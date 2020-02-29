------------------------ edge connector pin mapping ------------------------------
----------------------------------------------------------------------------------
-- See here : https://makecode.microbit.org/device/pins --------------------------

--  pin(code)      pin (edge connector pads)      hardware connected
--   0         --  large pad 0                   -- servo motor control pwm pin
--   1         --  large pad 1                   -- Flame Sense IR module
--   2         --  large pad 2                   -- Smoke Sense Photo diode
--   3         --  small pad/Display column 1    -- 2.5V  Sense reference TL431
--   4         --  small pad/Display column 2    -- NGas  Sense MQ-05
--   5         --  small pad/Button A            -- Reset Fault
--   6         --  small pad/Display column 9    -- NGas detected RED LED 3
--   7         --  small pad/Display column 8    -- Alarm Active YELLOW LED 3
--   8         --  small pad                     -- Flame detected RED LED 2
--   9         --  small pad/Display column 7    -- Equake detected YELLOW LED 1
--   10        --  small pad/Display column 3    -- Floof water Sense
--   11        --  small pad/Button B            -- Clear Alarm
--   12        --  small pad                     -- mains ok GREEN LED 1
--   13        --  small pad/SCK                 -- Smoke detected RED LED 1
--   14        --  small pad/MISO                -- Flood detected YELLOW LED 2
--   15        --  small pad/MOSI                -- Buzzer Alarm
--   16        --  small pad                     -- fault reset GREEN LED 2
--   19        --  small pad/SCL                 -- to Accelero Sensor onboard
--   20        --  small pad/SDA                 -- to Accelero Sensor onboard
----------------------------------------------------------------------------------
------------------------- end of comment section ---------------------------------

 -- packages/drivers

with MicroBit.IOs;     use MicroBit.IOs;     -- includes microbit GPIO   
with MicroBit.Time;                          -- includes microbit time   
with MicroBit.Buttons; use MicroBit.Buttons; -- includes ubit button  
with MMA8653;          use MMA8653;          -- includes  acceleromete hal
with MicroBit.Accelerometer;                 -- includes acceleratometer 

 -- following part for variable declearation
procedure Main is
   Fault       : Boolean := False;
   Connected   : Boolean := True;
   Fault_Flag  : Integer := 0;
   ADCVal      : MicroBit.IOs.Analog_Value; -- variable type for ADC reading
   ADCtemp     : MicroBit.IOs.Analog_Value; -- ADC type temp variable

   RedLED1_Smoke    : constant MicroBit.IOs.Pin_Id := 13;
   RedLED2_Flame    : constant MicroBit.IOs.Pin_Id := 8;
   RedLED3_NGas     : constant MicroBit.IOs.Pin_Id := 6;
   YellowLED1_Quake : constant MicroBit.IOs.Pin_Id := 9;
   YellowLED2_Flood : constant MicroBit.IOs.Pin_Id := 14;
   YellowLED3_Alarm : constant MicroBit.IOs.Pin_Id := 7;
   GreenLED1_Mains  : constant MicroBit.IOs.Pin_Id := 12;
   GreenLED2_Reset  : constant MicroBit.IOs.Pin_Id := 16;
   Servo_Pin        : constant MicroBit.IOs.Pin_Id := 0;
   Buzzer_Pin       : constant MicroBit.IOs.Pin_Id := 15;

-- following part for initialization (one time run code)
begin
   MicroBit.Accelerometer.Initialize; -- begin Accelerometer 
   -- set all status LEDs low (LEDs are CC, active low , see schematic)
   -- set all status LEDs low (LEDs are CC, active low , see schematic)
   -- set all status LEDs low (LEDs are CC, active low , see schematic)
   MicroBit.IOs.Set (RedLED1_Smoke, True);
   MicroBit.IOs.Set (RedLED2_Flame, True);
   MicroBit.IOs.Set (RedLED3_NGas, True);
   MicroBit.IOs.Set (YellowLED1_Quake , True);
   MicroBit.IOs.Set (YellowLED2_Flood , True);
   MicroBit.IOs.Set (GreenLED2_Reset , True);
   MicroBit.Time.Delay_Ms (500); -- ms delay function
   MicroBit.IOs.Set(Servo_Pin,False);
   MicroBit.IOs.Set(Buzzer_Pin,False);


   --  next part infinite loop (main loop run code)
   loop

      while Fault = False loop
         MicroBit.IOs.Set(GreenLED1_Mains, False);
         -- Analog voltage on ADC pin 3 is 2.5V reference
         -- detect smoke
      ADCtemp := MicroBit.IOs.Analog(3) - 300; -- adjust sensivity
      ADCVal := MicroBit.IOs.Analog (2); -- read ADC on pin 2 Photo Diode(smoke)

         if ADCVal >=ADCtemp then
         MicroBit.IOs.Set (RedLED1_Smoke, True); -- Write High to Disble LED
         else
            Fault := True; Fault_Flag := 1;
            Connected := False;
         end if;

         -- detect flame
      ADCtemp := MicroBit.IOs.Analog(3) - 450 ; -- adjust sensivity
      ADCVal := MicroBit.IOs.Analog (1); -- read ADC on pin 1 Flame Sensor
         if ADCVal >=ADCtemp then
         MicroBit.IOs.Set (RedLED2_Flame , True); -- Write High to Disble LED
         else
            Fault := True; Fault_Flag := 2;
            Connected := False;
         end if;

            -- detect gas
      ADCtemp := MicroBit.IOs.Analog(3)-420 ; -- adjust sensivity
      ADCVal := MicroBit.IOs.Analog (4); -- read ADC on pin 4 gas Sensor
         if ADCVal <=ADCtemp then
         MicroBit.IOs.Set (RedLED3_NGas , True); -- xWrite High to Disble LED
         else
            Fault := True; Fault_Flag := 3;
            Connected := False;
         end if;

         -- detect earthquake
         if (MicroBit.Accelerometer.Data.Y <1) then -- read accelerometer y norm
          MicroBit.IOs.Set (YellowLED1_Quake , True);
         else
           Fault := True; Fault_Flag := 4;
            Connected := False;
         end if;
         -- detect flood water
          ADCtemp := MicroBit.IOs.Analog(3) -200 ; -- adjust sensivity
         ADCVal := MicroBit.IOs.Analog (10); -- read ADC on pin 10 flood
         if ADCVal >=ADCtemp then
         MicroBit.IOs.Set (YellowLED2_Flood , True); -- Write High to Disble LED
         else
            Fault := True; Fault_Flag := 5;
            Connected := False;
         end if;



      end loop;

      if Fault then
          MicroBit.IOs.Set(GreenLED1_Mains, True);
            -- Move servo arm to turn off mcb
            for tempval in 0 .. 9 loop
            MicroBit.IOs.Set(Servo_Pin,True);
            MicroBit.Time.Delay_Ms(1);
            MicroBit.IOs.Set(Servo_Pin,False);
            MicroBit.Time.Delay_Ms(19);
            end loop;
        MicroBit.Time.Delay_Ms(200);
         -- Move Servo arm to stand by position
         -- 50 Hz, 5% duty signal for servo
            for tempval in 0 .. 9 loop
            MicroBit.IOs.Set(Servo_Pin,True);
            MicroBit.Time.Delay_Ms(2);
            MicroBit.IOs.Set(Servo_Pin,False);
            MicroBit.Time.Delay_Ms(18);
            end loop;
         end if;



      while Fault loop
        if MicroBit.Buttons.State (Button_B) = Pressed then -- check button B
            Fault :=False;
            MicroBit.IOs.Set(YellowLED3_Alarm,True);
            MicroBit.IOs.Set(Buzzer_Pin,False);
         end if;
         MicroBit.IOs.Set(YellowLED3_Alarm,False);
         MicroBit.IOs.Set(Buzzer_Pin,True);
         case Fault_Flag is
            when 1 =>
            -- smoke fault blinkey
            MicroBit.IOs.Set (RedLED1_Smoke, False);
            MicroBit.Time.Delay_Ms (100);
            MicroBit.IOs.Set (RedLED1_Smoke, True);
            MicroBit.IOs.Set(Buzzer_pin,False);
            MicroBit.Time.Delay_Ms (100);
            when 2 =>
            -- fire fault blinkey
            MicroBit.IOs.Set (RedLED2_Flame, False);
            MicroBit.Time.Delay_Ms (100);
            MicroBit.IOs.Set (RedLED2_Flame, True);
            MicroBit.IOs.Set(Buzzer_pin,False);
            MicroBit.Time.Delay_Ms (100);
            when 3 =>
            -- gas fault blinkey
            MicroBit.IOs.Set (RedLED3_NGas, False);
            MicroBit.Time.Delay_Ms (100);
            MicroBit.IOs.Set (RedLED3_NGas, True);
            MicroBit.IOs.Set(Buzzer_pin,False);
            MicroBit.Time.Delay_Ms (100);
            when 4 =>
            -- earthquake fault blinkey
            MicroBit.IOs.Set (YellowLED1_Quake, False);
            MicroBit.Time.Delay_Ms (100);
            MicroBit.IOs.Set (YellowLED1_Quake, True);
            MicroBit.IOs.Set(Buzzer_pin,False);
            MicroBit.Time.Delay_Ms (100);
            when 5 =>
            -- flood water fault blinkey
            MicroBit.IOs.Set (YellowLED2_Flood, False);
            MicroBit.Time.Delay_Ms (100);
            MicroBit.IOs.Set (YellowLED2_Flood, True);
            MicroBit.IOs.Set(Buzzer_pin,False);
            MicroBit.Time.Delay_Ms (100);
            when others =>
               -- do nothing
               null;
         end case;


      end loop;

      while Connected = False loop
        if MicroBit.Buttons.State (Button_A) = Pressed then -- check button A
            Connected := True; Fault_Flag := 0;
         end if;
         MicroBit.IOs.Set (GreenLED2_Reset , False);
         MicroBit.Time.Delay_Ms (50);
         MicroBit.IOs.Set (GreenLED2_Reset , True);
         MicroBit.Time.Delay_Ms (40);
      end loop;



    

      MicroBit.Time.Delay_Ms (1); 



      MicroBit.IOs.Set (RedLED1_Smoke, False);
      MicroBit.IOs.Set (RedLED2_Flame, False);
      MicroBit.IOs.Set (RedLED3_NGas, False);
      MicroBit.IOs.Set (YellowLED1_Quake, False);
      MicroBit.IOs.Set (YellowLED2_Flood, False);
      MicroBit.IOs.Set (YellowLED3_Alarm, False);
      MicroBit.Time.Delay_Ms (100);
      MicroBit.IOs.Set (RedLED1_Smoke, True);
      MicroBit.IOs.Set (RedLED3_NGas, True);
      MicroBit.IOs.Set (RedLED2_Flame, True);
      MicroBit.IOs.Set (YellowLED1_Quake, True);
      MicroBit.IOs.Set (YellowLED2_Flood, True);
       MicroBit.IOs.Set (YellowLED3_Alarm, True);
      MicroBit.Time.Delay_Ms (300);



   end loop;
end Main;

-- I have written this code based on examples/drivers from the following link:
-- https://github.com/AdaCore/Ada_Drivers_Library/tree/master/boards/MicroBit
-- by Fabien-Chouteau's work on behalf of ADA driver library on github        

-- DISCLAIMER: License agreement as per contest rules  --

