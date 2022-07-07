function send_trigger(p,trigger,dt)
% function send_trigger(trigger,dt)

if(~exist('dt'))
    dt = 0.004; %4ms (2ms causes audio artifacts)
end

if p.usetrigs
    DaqDOut(p.di,0,trigger);  %send trigger
    WaitSecs(dt);
    DaqDOut(p.di,0,0);  %clear trig
end

%old code with parallel port
%lptwrite(888,trigger);
%WaitSecs(dt);
%lptwrite(888,0);

