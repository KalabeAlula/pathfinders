import 'dart:async';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Minimal VM-service capture: frame timeline, CPU samples and memory for the
/// running app. Usage: dart tool/perf_capture.dart <vm-service-uri> <seconds>
Future<void> main(List<String> args) async {
  final raw = args.first;
  final seconds = int.tryParse(args.length > 1 ? args[1] : '5') ?? 5;
  final base = raw.replaceFirst('http://', 'ws://').replaceFirst(
    RegExp(r'/$'),
    '',
  );
  final service = await vmServiceConnectUri('$base/ws');

  try {
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere(
      (candidate) => candidate.name == 'main',
      orElse: () => vm.isolates!.first,
    );
    stdout.writeln('isolate: ${isolate.name} (${isolate.id})');

    final memory = await service.getMemoryUsage(isolate.id!);
    stdout.writeln(
      'heap: ${_mb(memory.heapUsage)}MB / ${_mb(memory.heapCapacity)}MB '
      'external: ${_mb(memory.externalUsage)}MB',
    );

    await service.setVMTimelineFlags(['Dart', 'Embedder', 'GC']);
    await service.clearVMTimeline();

    final clock = await service.getVMTimelineMicros();
    final cpuStart = clock.timestamp ?? 0;
    await Future<void>.delayed(Duration(seconds: seconds));

    final timeline = await service.getVMTimeline();
    _reportTimeline(
      timeline.traceEvents ?? const <TimelineEvent>[],
      seconds,
    );

    try {
      final cpu = await service.getCpuSamples(
        isolate.id!,
        cpuStart,
        seconds * 1000000,
      );
      _reportCpu(cpu);
    } on Object catch (error) {
      stdout.writeln('cpu samples unavailable: $error');
    }
  } finally {
    await service.dispose();
  }
}

void _reportTimeline(List<TimelineEvent> events, int seconds) {
  final durations = <String, List<int>>{};
  final phases = <String, int>{};
  final open = <String, List<int>>{};

  void close(String name, int elapsed) {
    durations.putIfAbsent(name, () => <int>[]).add(elapsed);
  }

  for (final event in events) {
    final json = event.json;
    if (json == null) continue;
    final phase = json['ph'];
    if (phase is! String) continue;
    phases[phase] = (phases[phase] ?? 0) + 1;
    final name = json['name'];
    final ts = json['ts'];
    if (name is! String || ts is! int) continue;
    final key = '${json['tid']}|$name|${json['id'] ?? ''}';
    switch (phase) {
      case 'X':
        final dur = json['dur'];
        if (dur is int) close(name, dur);
      case 'B':
      case 'b':
        open.putIfAbsent(key, () => <int>[]).add(ts);
      case 'E':
      case 'e':
        final begin = open[key];
        if (begin != null && begin.isNotEmpty) {
          close(name, ts - begin.removeLast());
        }
    }
  }

  stdout.writeln(
    'timeline: ${events.length} events '
    '(phases: ${phases.entries.map((e) => '${e.key}=${e.value}').join(', ')})',
  );

  const interesting = <String>[
    'Frame',
    'GPURasterizer::Draw',
    'Animator::BeginFrame',
    'Impeller',
  ];
  for (final entry in durations.entries) {
    final matches =
        interesting.any((needle) => entry.key.contains(needle)) &&
        entry.value.length >= 5;
    if (!matches) continue;
    final sorted = [...entry.value]..sort();
    final total = sorted.fold<int>(0, (sum, value) => sum + value);
    final over16 = sorted.where((value) => value > 16667).length;
    final over33 = sorted.where((value) => value > 33333).length;
    stdout.writeln(
      '${entry.key.padRight(28)} n=${sorted.length.toString().padLeft(4)} '
      'avg=${(total / sorted.length / 1000).toStringAsFixed(2)}ms '
      'p50=${_p(sorted, 0.50)} p90=${_p(sorted, 0.90)} '
      'p99=${_p(sorted, 0.99)} max=${_p(sorted, 1.0)} '
      '>16.7ms=${(over16 / sorted.length * 100).toStringAsFixed(0)}% '
      '>33ms=${(over33 / sorted.length * 100).toStringAsFixed(0)}%',
    );
  }

  final frameCount = durations['Frame']?.length ?? 0;
  if (frameCount > 0) {
    stdout.writeln(
      'frames in ${seconds}s: $frameCount '
      '(${(frameCount / seconds).toStringAsFixed(1)} fps)',
    );
  }

  final slow = <MapEntry<String, List<int>>>[
    for (final entry in durations.entries)
      if (entry.value.length >= 5 &&
          interesting.every((needle) => !entry.key.contains(needle)))
        entry,
  ]..sort(
    (a, b) => b.value.fold<int>(0, (s, v) => s + v).compareTo(
      a.value.fold<int>(0, (s, v) => s + v),
    ),
  );
  stdout.writeln('other long events:');
  for (final entry in slow.take(8)) {
    final sorted = [...entry.value]..sort();
    stdout.writeln(
      '  ${entry.key.padRight(34)} n=${entry.value.length} '
      'avg=${((sorted.fold<int>(0, (s, v) => s + v)) / sorted.length / 1000).toStringAsFixed(2)}ms '
      'max=${_p(sorted, 1.0)}',
    );
  }
}

void _reportCpu(CpuSamples cpu) {
  final functions = cpu.functions ?? const <ProfileFunction>[];
  final ranked = functions
      .where((function) => (function.exclusiveTicks ?? 0) > 0)
      .toList()
    ..sort(
      (a, b) =>
          (b.exclusiveTicks ?? 0).compareTo(a.exclusiveTicks ?? 0),
    );
  final total = functions.fold<int>(
    0,
    (sum, function) => sum + (function.exclusiveTicks ?? 0),
  );
  if (total == 0) {
    stdout.writeln('cpu samples: none (${cpu.sampleCount ?? 0})');
    return;
  }
  stdout.writeln(
    'top CPU functions (${cpu.sampleCount ?? 0} samples, '
    '${cpu.samplePeriod}us period):',
  );
  for (final function in ranked.take(14)) {
    final name = _name(function);
    stdout.writeln(
      '  ${((function.exclusiveTicks ?? 0) / total * 100).toStringAsFixed(1).padLeft(5)}% '
      '$name ${_url(function)}',
    );
  }
}

String _name(ProfileFunction function) {
  final target = function.function;
  if (target is FuncRef) {
    final name = target.name ?? '';
    if (name.isNotEmpty) return name;
  }
  final kind = function.kind ?? '';
  final url = function.resolvedUrl ?? '';
  final file = url.isEmpty ? '' : url.split('/').last;
  return '[$kind] ${file.isEmpty ? '<unknown>' : file}';
}

String _url(ProfileFunction function) {
  final url = function.resolvedUrl ?? '';
  if (url.isEmpty) return '';
  final short = url.split('/').last;
  return '($short)';
}

String _p(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return '-';
  final index = ((sorted.length - 1) * percentile).round();
  return '${(sorted[index] / 1000).toStringAsFixed(1)}ms';
}

String _mb(int? bytes) =>
    bytes == null ? '-' : (bytes / (1024 * 1024)).toStringAsFixed(1);
