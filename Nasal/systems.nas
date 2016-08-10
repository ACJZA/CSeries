## Bombardier CRJ700 series
## adapted for Bombardier CSeries
## Aircraft systems
###########################

## Main systems update loop
var Systems = {

    fast_loopid: -1,
    slow_loopid: -1,
    init: func
    {
        print("Systems ... initialized");
        Systems.start();
        # create crossfeed valve
        var gravity_xflow = aircraft.crossfeed_valve.new(0.5, "controls/fuel/gravity-xflow", 0, 1);
        gravity_xflow.open();
    },
    start: func
    {
        Systems.fast_update(Systems.fast_loopid += 1);
        Systems.slow_update(Systems.slow_loopid += 1);
    },
    stop: func
    {
        Systems.fast_loopid += 1;
        Systems.slow_loopid += 1;
    },
    reinit: func
    {
        print("CS100 aircraft systems ... reinitialized");
        setprop("sim/model/start-idling", 0);
        Systems.stop();
        Systems.start();
    },
    fast_update: func(loopid)
    {
        if (loopid != Systems.fast_loopid) return;
        engine1.update();
        engine2.update();
        apu1.update();
        update_electrical();
        if (!props.globals.getNode("sim/crashed").getBoolValue())
        {
            settimer(func
            {
                Systems.fast_update(loopid);
            }, 0);
        }
    },
    slow_update: func(loopid)
    {
        if (loopid != Systems.slow_loopid) return;
       # update_tat();
        rat1.update();
      #  update_copilot_ints();
      #  update_pass_signs();
      #  update_lightmaps();
        if (!props.globals.getNode("sim/crashed").getBoolValue())
        {
            settimer(func
            {
                Systems.slow_update(loopid);
            }, 3);
        }
    }
};
setlistener("sim/signals/fdm-initialized", func settimer(Systems.init, 2), 0, 0);
setlistener("sim/signals/reinit", func(v) if (v.getBoolValue()) Systems.reinit(), 0, 0);

## Startup/shutdown functions
var startid = 0;
var startup = func
{
    startid += 1;
    var id = startid;
    setprop("controls/electric/battery-switch", 1);
    setprop("controls/pneumatic/bleed-source", 2);
    setprop("controls/APU/off-on", 1);
    setprop("controls/engines/engine[0]/cutoff", 0);
    setprop("controls/engines/engine[1]/cutoff", 0);
    settimer(func
    {
        if (id == startid)
        {
            engine1.start();
            engine2.start();
            setprop("controls/electric/engine[0]/generator", 1);
            setprop("controls/electric/engine[1]/generator", 1);
            settimer(func
            {
                if (id == startid)
                {
                    setprop("controls/APU/off-on", 0);
                    setprop("controls/electric/battery-switch", 0);
                }
            }, 7);
        }
    }, 11);
};
var shutdown = func
{
    setprop("controls/engines/engine[0]/cutoff", 1);
    setprop("controls/engines/engine[1]/cutoff", 1);
    setprop("controls/electric/engine[0]/generator", 0);
    setprop("controls/electric/engine[1]/generator", 0);
};
setlistener("sim/model/start-idling", func(v)
{
    var run = v.getBoolValue();
    if (run)
    {
        startup();
    }
    else
    {
        shutdown();
    }
}, 0, 0);

## Instant start for tutorials and whatnot
var instastart = func
{
    setprop("controls/electric/engine[0]/generator", 1);
    setprop("controls/electric/engine[1]/generator", 1);
    setprop("controls/engines/engine[0]/cutoff", 0);
    engine1.start();
    setprop("engines/engine[0]/rpm", 25);
    setprop("controls/engines/engine[1]/cutoff", 0);
    engine2.start();
    setprop("engines/engine[1]/rpm", 25);
};

## Prevent the gear from being retracted on the ground
setlistener("controls/gear/gear-down", func(v)
{
    if (!v.getBoolValue())
    {
        var on_ground = 0;
        foreach (var gear; props.globals.getNode("gear").getChildren("gear"))
        {
            var wow = gear.getNode("wow", 0);
            if (wow != nil and wow.getBoolValue()) on_ground = 1;
        }
        if (on_ground) v.setBoolValue(1);
    }
}, 0, 0);

## Engines at cutoff by default (not specified in -set.xml because that means they will be set to 'true' on a reset)
setprop("controls/engines/engine[0]/cutoff", 1);
setprop("controls/engines/engine[1]/cutoff", 1);

## Wipers
#var Wiper = {
#    new: func(inP, outP, onP, pwrP)
#    {
#        var m = { parents: [Wiper] };
#        m.active = 0;
#        m.ctl_node = props.globals.getNode(inP, 1);
#        setlistener (inP, func
#        {
#            m.switch();
 #       });
  #      m.out_node = props.globals.getNode(outP, 1);
   #     m.on_node = props.globals.getNode(onP, 1);
    #    m.pwr_node = props.globals.getNode(pwrP, 1);
     #   setlistener (pwrP, func
      #  {
       #     m.switch();
        #});
#        return m;
 #   },
  #  switch: func
   # {
    #    var switch_val = me.ctl_node.getValue();
     #   if (switch_val > 0)
      #  {
       #     me.on_node.setBoolValue(1);
        #    if (!me.active and me.pwr_node.getValue() >= 15)
         #   {
          #      var wiper_time = 1 / switch_val;
           #     interpolate(me.out_node, 1, wiper_time, 0, wiper_time);
            #    settimer (func
             #   {
              #      me.update();
               # }, wiper_time * 2);
#                #me.active = 1;
 #           }
  #      }
   # },
    #update: func
    #{
      #  var switch_val = me.ctl_node.getValue();
     #   if (switch_val <= 0)
       # {
        #    me.active = 0;
         #   me.on_node.setBoolValue(0);
  #      }
   #     else
    #    {
     #       me.on_node.setBoolValue(1);
      #      if (me.pwr_node.getValue() >= 15)
       #     {
        #        var wiper_time = 1 / switch_val;
         #       interpolate(me.out_node, 1, wiper_time, 0, wiper_time);
          #      settimer (func
           #     {
            #        me.update();
             #   }, wiper_time * 2);
              #  me.active = 1;
#            }
 #           else
  #          {
   #             me.active = 0;
    #        }
     #   }
    #}
#};
#var left_wiper = Wiper.new("controls/anti-ice/wiper[0]", "surface-positions/left-wiper-pos-norm", "controls/anti-ice/wiper-power[0]", "systems/electrical/outputs/#wiper[0]");
#var right_wiper = Wiper.new("controls/anti-ice/wiper[1]", "surface-positions/right-wiper-pos-norm", "controls/anti-ice/wiper-power[1]", "systems/electrical/outputs/#wiper[1]");

## RAT
var Rat = {
    new: func(node, trigger_prop)
    {
        var m = { parents: [Rat] };
        m.powering = 0;
        m.node = aircraft.makeNode(node);
        var nodeP = m.node.getPath();
        m.serviceableN = props.globals.initNode(nodeP ~ "/serviceable", 1, "BOOL");
        m.positionN = props.globals.initNode(nodeP ~ "/position-norm", 0, "DOUBLE");
        m.rpmN = props.globals.initNode(nodeP ~ "/rpm", 0, "DOUBLE");
        m.triggerN = aircraft.makeNode(trigger_prop);
        setlistener(m.triggerN, func(v)
        {
            if (v.getBoolValue()) m.deploy();
        }, 0, 0);
        m.deploy_time = 8; # typical RAT deploy time is ~8 seconds
        return m;
    },
    deploy: func
    {
        if (me.serviceableN.getBoolValue()) interpolate(me.positionN, 1, me.deploy_time);
    },
    update: func
    {
        if (me.serviceableN.getBoolValue() and me.positionN.getValue() >= 1)
        {
            # the CRJ's RAT operates at ~7000 to ~12000 RPM
            # "There are two different style Air Driven Generators (ADGs) used on CRJs.
            # One rotates at approximately 7,000 RPM, the other is much higher at 12,000 RPM."
            # see http://www.airliners.net/aviation-forums/tech_ops/read.main/274235/, reply #2
            # the RPM of the RAT begins dropping at 250 KTAS (TOTAL GUESS!)
            # threshold is 15 KTAS (ANOTHER TOTAL GUESS)
            var rpm = aircraft.kias_to_ktas(getprop("velocities/airspeed-kt"), getprop("position/altitude-ft")) * 28 - 15;
            if (rpm >= 7000) rpm = 7000;
            elsif (rpm <= 0) rpm = 0;
            me.rpmN.setDoubleValue(rpm);
        }
        else
        {
            me.rpmN.setDoubleValue(0);
        }
    }
};
var rat1 = Rat.new("systems/ram-air-turbine", "controls/pneumatic/ram-air-turbine");

setlistener("/sim/signals/fdm-initialized", func {
  itaf.ap_init();
  var autopilot = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/CSeries/Systems/autopilot-dlg.xml");
  setprop("/engines/engine[0]/n1-limit", "99.5");
  setprop("/engines/engine[1]/n1-limit", "99.5");
  setprop("/engines/engine[0]/itt-ind", "0.0");
  setprop("/engines/engine[1]/itt-ind", "0.0");
  setprop("/controls/engines/limit-type", "TO LIMIT");
  setprop("/controls/internal/value1", "1");
});