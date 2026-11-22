-- Browser push tokens register with platform 'web' next to the phone builds.
alter table public.device_push_tokens
  drop constraint if exists device_push_tokens_platform_check;

alter table public.device_push_tokens
  add constraint device_push_tokens_platform_check
  check (platform in ('android', 'ios', 'web'));
