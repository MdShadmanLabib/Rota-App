-- Rota — enable realtime broadcasts for live updates (employee status, rota
-- changes, requests, announcements). Safe to run repeatedly.

do $$
declare t text;
begin
  foreach t in array array[
    'shifts', 'leave_requests', 'swap_requests',
    'time_entries', 'announcements', 'availability'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception
      when duplicate_object then null;
      when undefined_object then null; -- publication not present in local dev
    end;
  end loop;
end $$;
