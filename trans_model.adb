with ada.text_io; use ada.text_io;
with ada.integer_text_io; use ada.integer_text_io;
with trans; use trans;   --for the token types
with ada.characters.handling; use ada.characters.handling;   --for To_Upper()
with ada.strings; use ada.strings;   --for Backward, Forward
with ada.strings.fixed; use ada.strings.fixed;   --for Index()
with ada.strings.unbounded; use ada.strings.unbounded;
with lego;   --for Ada/Mindstorms builtins
with lego_builtins;   --"
with type_membership_template;   --for type membership generics below
with lists_generic;

package body trans_model is

--generic subprogram instantiations for Ada/Mindstorms type membership checking
--all of form Is_This_Type(This : String) return boolean
function Is_Ada_Mindstorms_Procedure is
   new Type_Membership_Template(Discrete_Type => Lego.Ada_Mindstorms_Procedure);
function Is_Sensor_Port is
   new Type_Membership_Template(Discrete_Type => Lego.Sensor_Port);
function Is_Output_Port is
   new Type_Membership_Template(Discrete_Type => Lego.Output_Port);
function Is_Output_Mode is
   new Type_Membership_Template(Discrete_Type => Lego.Output_Mode);
function Is_Output_Direction is
   new Type_Membership_Template(Discrete_Type => Lego.Output_Direction);
function Is_Configuration is
   new Type_Membership_Template(Discrete_Type => Lego.Configuration);
function Is_Sensor_Type is
   new Type_Membership_Template(Discrete_Type => Lego.Sensor_Type);
function Is_Sound is
   new Type_Membership_Template(Discrete_Type => Lego.Sound);
function Is_Sensor_Mode is
   new Type_Membership_Template(Discrete_Type => Lego.Sensor_Mode);
function Is_Timer is
   new Type_Membership_Template(Discrete_Type => Lego.Timer);
function Is_Transmitter_Power_Setting is
   new Type_Membership_Template(Discrete_Type => Lego.Transmitter_Power_Setting);

--global variables, so sue me
Proc_Nesting_Level : Integer := 0;   --current level of procedure nesting
Indent_Level : Integer := 0;         --current indent level, so translated code looks nice

--constants
Max_NQC_Global_Variables : constant integer := 32;   --comes directly from NQC

--need these for user type declarations (arrays)
--in a future release, may want to replace these with hash tables
package Type_Decl_Lists is new Lists_Generic(type_decl_nonterminal);   
Global_Type_Decls : Type_Decl_Lists.list;   --type declarations that are global to the program
Local_Type_Decls : Type_Decl_Lists.list;    --type declarations local to the current procedure
package Object_Decl_Lists is new Lists_Generic(object_decl_nonterminal);   
Global_Object_Decls : Object_Decl_Lists.list;   --object declarations that are global to the program
Local_Object_Decls : Object_Decl_Lists.list;    --object declarations local to the current procedure


function Is_Global_Variable(Id_String: in Unbounded_String) return boolean is
   Current : Object_Decl_Lists.Position;
   Decl : Object_Decl_nonterminal;
   Id_Tkn : Parseable_Token_Ptr := new Parseable_Token;
   
begin
   Current := Object_Decl_Lists.First(Global_Object_Decls);
   while not Object_Decl_Lists.IsPastEnd(Global_Object_Decls, Current) loop
      Decl := Object_Decl_Lists.Retrieve(Global_Object_Decls, Current);
      
      --call to In_Id_List below requires a token, not a string
      Id_Tkn.Line := 0;
      Id_Tkn.Column := 0;   --not worth it to set these to correct values
      Id_Tkn.Token_String := new String'(To_String(Id_String));
      Id_Tkn.Token_Type := Identifier_Token;
      
      --Is this the right one?
      if In_Id_List(Decl.def_id_s_part.all, Id_Tkn) and not Is_Constant_Declaration(Decl) then
         return true;
      end if;
      Object_Decl_Lists.GoAhead(Global_Object_Decls, Current);
   end loop;
   return false;
end Is_Global_Variable;

function Is_Global_Constant(Id_String: in Unbounded_String) return boolean is
   Current : Object_Decl_Lists.Position;
   Decl : Object_Decl_nonterminal;
   Id_Tkn : Parseable_Token_Ptr := new Parseable_Token;
begin
   Current := Object_Decl_Lists.First(Global_Object_Decls);
   while not Object_Decl_Lists.IsPastEnd(Global_Object_Decls, Current) loop
      Decl := Object_Decl_Lists.Retrieve(Global_Object_Decls, Current);
      
      --call to In_Id_List below requires a token, not a string
      Id_Tkn.Line := 0;
      Id_Tkn.Column := 0;   --not worth it to set these to correct values
      Id_Tkn.Token_String := new String'(To_String(Id_String));
      Id_Tkn.Token_Type := Identifier_Token;
      
      --Is this the right one?
      if In_Id_List(Decl.def_id_s_part.all, Id_Tkn) then
         return true;
      end if;
      
      Object_Decl_Lists.GoAhead(Global_Object_Decls, Current);
   end loop;
   return false;
end Is_Global_Constant;

function Is_Local_Variable(Id_String: in Unbounded_String) return boolean is
   Current : Object_Decl_Lists.Position;
   Decl : Object_Decl_nonterminal;
   Id_Tkn : Parseable_Token_Ptr := new Parseable_Token;
begin
   Current := Object_Decl_Lists.First(Local_Object_Decls);
   while not Object_Decl_Lists.IsPastEnd(Local_Object_Decls, Current) loop
      Decl := Object_Decl_Lists.Retrieve(Local_Object_Decls, Current);
      
      --call to In_Id_List below requires a token, not a string
      Id_Tkn.Line := 0;
      Id_Tkn.Column := 0;   --not worth it to set these to correct values
      Id_Tkn.Token_String := new String'(To_String(Id_String));
      Id_Tkn.Token_Type := Identifier_Token;
      
      --Is this the right one?
      if In_Id_List(Decl.def_id_s_part.all, Id_Tkn) and not Is_Constant_Declaration(Decl) then
         return true;
      end if;
      Object_Decl_Lists.GoAhead(Local_Object_Decls, Current);
   end loop;
   return false;
end Is_Local_Variable;

function Is_Local_Constant(Id_String: in Unbounded_String) return boolean is
   Current : Object_Decl_Lists.Position;
   Decl : Object_Decl_nonterminal;
   Id_Tkn : Parseable_Token_Ptr := new Parseable_Token;
begin
   Current := Object_Decl_Lists.First(Local_Object_Decls);
   while not Object_Decl_Lists.IsPastEnd(Local_Object_Decls, Current) loop
      Decl := Object_Decl_Lists.Retrieve(Local_Object_Decls, Current);
      
      --call to In_Id_List below requires a token, not a string
      Id_Tkn.Line := 0;
      Id_Tkn.Column := 0;   --not worth it to set these to correct values
      Id_Tkn.Token_String := new String'(To_String(Id_String));
      Id_Tkn.Token_Type := Identifier_Token;
      
      --Is this the right one?
      if In_Id_List(Decl.def_id_s_part.all, Id_Tkn) then
         return true;
      end if;
      Object_Decl_Lists.GoAhead(Local_Object_Decls, Current);
   end loop;
   return false;
end Is_Local_Constant;



-------------------
-- Number_Of_Vars --
-------------------
function Number_Of_Vars(decl_list : Object_Decl_Lists.list) return integer is
Current : Object_Decl_Lists.Position;
Decl : object_decl_nonterminal;
Total : integer := 0;
begin
   Current := Object_Decl_Lists.First(decl_list);
   while not Object_Decl_Lists.IsPastEnd(decl_list, Current) loop
      Decl := Object_Decl_Lists.Retrieve(decl_list, Current);
      Total := Total + Number_Of_Vars(Decl);
      Object_Decl_Lists.GoAhead(decl_list, Current);
   end loop; 
   return Total;
end Number_Of_Vars;
   
procedure Inc_Indent is
begin
   Indent_Level := Indent_Level+1;
end Inc_Indent;

procedure Dec_Indent is
begin
   Indent_Level := Indent_Level-1;
end Dec_Indent;

procedure my_new_line is
begin
   new_line;
   for i in 1..Indent_Level loop
      put("   ");
   end loop;
end my_new_line;

procedure put_with_space(Item: String) is
begin
   put(Item);
   put(" ");
end put_with_space;

procedure put_with_space(Item: Unbounded_String) is
begin
   put(To_String(Item));
   put(" ");
end put_with_space;

procedure put_with_space(Item : Integer) is
begin
   put(Item => Item, Width => 0);
   put(" ");
end put_with_space;

Input_Filename : Unbounded_String;   --need this for error messages
--called from main program
procedure Set_Input_Filename(Name : in Unbounded_String) is
begin
   --strip off everything but the trailing component of the full path
   Input_Filename := To_Unbounded_String(Slice(
      Source => Name, 
      Low => Index(Source => Name, Pattern => "\", Going => Backward)+1,
      High => Length(Name)));
end Set_Input_Filename;

procedure Error_Msg_Prefix(Line, Column : in integer) is
begin
   put(File => Standard_Error, Item => To_String(Input_Filename));
   put(File => Standard_Error, Item => ":");
   put(File => Standard_Error, Width => 0, Item => Line);
   put(File => Standard_Error, Item => ":");
   put(File => Standard_Error, Width => 0, Item => Column);
end Error_Msg_Prefix;

--Should have an entry for every Ada/Mindstorms identifier, even if
--it's just passed through.  Must be kept consistent with lego.ads.
procedure Translate_Ada_Mindstorms_Identifier(This : String) is
ID_String : Unbounded_String := To_Unbounded_String(To_Upper(This));
begin
   if ID_String = "ADD_TO_DATALOG" then
      put("AddToDatalog");
   elsif ID_String = "CLEAR_MESSAGE_BUFFER" then
      put("ClearMessage");
   elsif ID_String = "CLEAR_SENSOR" then
      put("ClearSensor");
   elsif ID_String = "CLEAR_SOUND_BUFFER" then
      put("ClearSound");
   elsif ID_String = "CLEAR_TIMER" then
      put("ClearTimer");
   elsif ID_String = "CONFIG_SENSOR" then
      put("SetSensor");
   elsif ID_String = "CREATE_DATALOG" then
      put("CreateDatalog");
   elsif ID_String = "DISPLAY_VALUE" then
      put("SetUserDisplay");
   elsif ID_String = "GET_BOOLEAN_SENSOR_VALUE" then
      put("SensorValueBool");
   elsif ID_String = "GET_GLOBAL_OUTPUT_MODE" then
      put("GlobalOutputStatus");
   elsif ID_String = "GET_MESSAGE" then
      put("Message");
   elsif ID_String = "GET_OUTPUT_MODE" then
      put("OutputStatus");
   elsif ID_String = "GET_RAW_SENSOR_VALUE" then
      put("SensorValueRaw");
   elsif ID_String = "GET_SENSOR_MODE" then
      put("SensorMode");
   elsif ID_String = "GET_SENSOR_TYPE" then
      put("SensorType");
   elsif ID_String = "GET_SENSOR_VALUE" then
      put("");   --Get_Sensor_Value(Sensor_x) becomes (SENSOR_x) in NQC
   elsif ID_String = "GET_TIMER" then
      put("Timer");
   elsif ID_String = "GET_WATCH" then
      put("Watch");
   elsif ID_String = "OUTPUT_FLOAT" then
      put("Float");
   elsif ID_String = "OUTPUT_FORWARD" then
      put("Fwd");
   elsif ID_String = "OUTPUT_OFF" then
      put("Off");
   elsif ID_String = "OUTPUT_ON" then
      put("On");
   elsif ID_String = "OUTPUT_ON_FOR" then
      put("OnFor");
   elsif ID_String = "OUTPUT_ON_FORWARD" then
      put("OnFwd");
   elsif ID_String = "OUTPUT_ON_REVERSE" then
      put("OnRev");
   elsif ID_String = "OUTPUT_REVERSE" then
      put("Rev");
   elsif ID_String = "OUTPUT_TOGGLE" then
      put("Toggle");
   elsif ID_String = "OUTPUT_POWER" then
      put("SetPower");
   elsif ID_String = "PLAY_SOUND" then
      put("PlaySound");
   elsif ID_String = "PLAY_TONE" then
      put("PlayTone");
   elsif ID_String = "RANDOM" then
      put("Random");
    elsif ID_String = "SELECT_DISPLAY" then
      put("SelectDisplay");
   elsif ID_String = "SEND_MESSAGE" then
      put("SendMessage");
   elsif ID_String = "SENSOR_1" then
      put("SENSOR_1");
   elsif ID_String = "SENSOR_2" then
      put("SENSOR_2");
   elsif ID_String = "SENSOR_3" then
      put("SENSOR_3");
   elsif ID_String = "SET_GLOBAL_OUTPUT_DIRECTION" then
      put("SetGlobalDirection");
   elsif ID_String = "SET_GLOBAL_OUTPUT_MODE" then
      put("SetGlobalOutput");
   elsif ID_String = "SET_MAX_POWER" then
      put("SetMaxPower");
   elsif ID_String = "SET_OUTPUT_DIRECTION" then
      put("SetDirection");
   elsif ID_String = "SET_OUTPUT_MODE" then
      put("SetOutput");
   elsif ID_String = "SET_SENSOR" then
      put("SetSensor");
   elsif ID_String = "SET_SENSOR_MODE" then
      put("SetSensorMode");
   elsif ID_String = "SET_SENSOR_TYPE" then
      put("SetSensorType");
   elsif ID_String = "SET_TRANSMITTER_POWER_LEVEL" then
      put("SetTxPower");
   elsif ID_String = "SPEAKER_OFF" then
      put("MuteSound");
   elsif ID_String = "SPEAKER_ON" then
      put("UnmuteSound");
   elsif ID_String = "STOP_ALL_TASKS" then
      put("StopAllTasks");
   elsif ID_String = "WAIT" then
      put("Wait");
   elsif Is_Configuration(To_String(ID_String)) then   --sensor configuration type, replace "Config_" with "Sensor_"
      put(To_String("SENSOR_" &
         To_Unbounded_String(Slice(Source => ID_String, Low => Index(Source => ID_String, Pattern => "_")+1,
         High => Length(ID_String)))));
   elsif Is_Sensor_Type(To_String(ID_String)) then   --sensor hardware type
      put(To_String("SENSOR_" & ID_String));
   elsif Is_Sound(To_String(ID_String)) then   --sound type
      put(To_String("SOUND_" & ID_String));
   elsif Is_Sensor_Mode(To_String(ID_String)) then   --mode type
      put(To_String("SENSOR_" & ID_String));        
   elsif ID_String = "OUTPUT_A" then   --output port designators
      put("OUT_A");
   elsif ID_String = "OUTPUT_B" then
      put("OUT_B");
   elsif ID_String = "OUTPUT_C" then
      put("OUT_C");
   elsif ID_String = "OUTPUT_MODE_ON" then   --output modes
      put("OUT_ON");
   elsif ID_String = "OUTPUT_MODE_OFF" then
      put("OUT_OFF");
   elsif ID_String = "OUTPUT_MODE_FLOAT" then
      put("OUT_FLOAT");
   elsif ID_String = "OUTPUT_DIRECTION_FORWARD" then   --output directions
      put("OUT_FWD");
   elsif ID_String = "OUTPUT_DIRECTION_REVERSE" then
      put("OUT_REV");
   elsif ID_String = "OUTPUT_DIRECTION_TOGGLE" then
      put("OUT_TOGGLE");
   elsif ID_String = "SET_WATCH" then
      put("SetWatch");
   elsif ID_String = "TIMER_0" then   --timers
      put("0");
   elsif ID_String = "TIMER_1" then
      put("1");
   elsif ID_String = "TIMER_2" then
      put("2");
   elsif ID_String = "TIMER_3" then
      put("3");
      
   elsif ID_String = "POWER_LOW" then   --power constants
      put_with_space(Integer(Lego.Power_Low));
   elsif ID_String = "POWER_HALF" then
      put_with_space(Integer(Lego.Power_Half));
   elsif ID_String = "POWER_HIGH" then
      put_with_space(Integer(Lego.Power_High));
      
   elsif ID_String = "TRUE" then   --boolean constants, reserved words in NQC so must be forced to lower case
      put_with_space("true");
   elsif ID_String = "FALSE" then
      put_with_space("false");
      
   elsif ID_String = "DISPLAY_WATCH" then   --display constants
      put_with_space(Lego.Display_Watch);
   elsif ID_String = "DISPLAY_SENSOR_1" then
      put_with_space(Lego.Display_Sensor_1);
   elsif ID_String = "DISPLAY_SENSOR_2" then
      put_with_space(Lego.Display_Sensor_2);
   elsif ID_String = "DISPLAY_SENSOR_3" then
      put_with_space(Lego.Display_Sensor_3);
   elsif ID_String = "DISPLAY_OUTPUT_A" then
      put_with_space(Lego.Display_Output_A);
   elsif ID_String = "DISPLAY_OUTPUT_B" then
      put_with_space(Lego.Display_Output_B);
   elsif ID_String = "DISPLAY_OUTPUT_C" then
      put_with_space(Lego.Display_Output_C);
   elsif ID_String = "DISPLAY_USER" then
      put_with_space(Lego.Display_User);
   elsif ID_String = "TRANSMITTER_POWER_LOW" then
      put_with_space("TX_POWER_LO");
   elsif ID_String = "TRANSMITTER_POWER_HIGH" then
      put_with_space("TX_POWER_HI");
      
   end if;

end Translate_Ada_Mindstorms_Identifier;

--must be kept consistent with power constant names in lego.ads
function Is_Power_Constant(This: in String) return boolean is
ID_String : Unbounded_String := To_Unbounded_String(To_Upper(This));
begin
   if ID_String = "POWER_LOW" or 
      ID_String = "POWER_HALF" or 
      ID_String = "POWER_HIGH" then
      return true;
   else
      return false;
   end if;
end Is_Power_Constant;

--must be kept consistent with display constant names in lego.ads
function Is_Display_Constant(This: in String) return boolean is
ID_String : Unbounded_String := To_Unbounded_String(To_Upper(This));
begin
   if ID_String = "DISPLAY_WATCH" or 
      ID_String = "DISPLAY_SENSOR_1" or 
      ID_String = "DISPLAY_SENSOR_2" or 
      ID_String = "DISPLAY_SENSOR_3" or 
      ID_String = "DISPLAY_OUTPUT_A" or 
      ID_String = "DISPLAY_OUTPUT_B" or 
      ID_String = "DISPLAY_OUTPUT_C" or 
      ID_String = "DISPLAY_USER" then 
      return true;
   else
      return false;
   end if;
end Is_Display_Constant;

function Is_Boolean_Constant(This : in String) return boolean is
ID_String : Unbounded_String := To_Unbounded_String(To_Upper(This));
begin
   if ID_String = "TRUE" or
      ID_String = "FALSE" then
      return true;
   else
      return false;
   end if;
end Is_Boolean_Constant;

function Is_Ada_Mindstorms_Identifier(This : in String) return boolean is
begin
   --call the generic subprograms instantiated at the beginning of this file
   if Is_Ada_Mindstorms_Procedure(This) or
      Is_Sensor_Port(This) or 
      Is_Sensor_Mode(This) or 
      Is_Sensor_Type(This) or
      Is_Output_Port(This) or
      Is_Output_Mode(This) or
      Is_Output_Direction(This) or
      Is_Configuration(This) or
      Is_Sound(This) or
      Is_Timer(This) or
      Is_Transmitter_Power_Setting(This) then
         return true;
   elsif Is_Power_Constant(This) then     --power constants treated specially
      return true;
   elsif Is_Display_Constant(This) then   --display constants treated specially
      return true;
   elsif Is_Boolean_Constant(This) then   --boolean constants treated specially
      return true;
   else
      return false;
   end if;
end Is_Ada_Mindstorms_Identifier;

function Is_In_Proc_Table(This : in String; Arity : in Integer) return boolean is
begin
   for i in 1..Lego_Builtins.Max_Procedures loop
   if (To_Upper(This) = To_Upper(To_String((Lego_Builtins.Procedure_Info_Table(i).Name)))) and 
         (Lego_Builtins.Procedure_Info_Table(i).arity = Arity) then
         return true;
      end if;
   end loop;
   return false;
end Is_In_Proc_Table;

procedure Get_Proc_Info(This : in String; Arity : in Integer; Line, Column : in Integer; 
   found : out boolean; Info : out Lego_Builtins.Procedure_Info_Record_Type) is
begin
   found := false;
   Info := Lego_Builtins.Procedure_Info_Table(1);   --initialize this to something in case desired record is never found
   for i in 1..Lego_Builtins.Max_Procedures loop
      if (To_Upper(This) = To_Upper(To_String((Lego_Builtins.Procedure_Info_Table(i).Name)))) and 
      (Lego_Builtins.Procedure_Info_Table(i).arity = Arity) then
         Info := Lego_Builtins.Procedure_Info_Table(i);
         found := true;
         return;
      end if;
   end loop;
end Get_Proc_Info;
   
function Name_Of_Formal_As_Declared (This : in indexed_comp_nonterminal; i : in Integer; Arity : in Integer) return Unbounded_String is
Info_Rec : Lego_Builtins.Procedure_Info_Record_Type;
Ignored1, Ignored2 : integer := 0;
Line, Column : integer;
Found : boolean;
begin
   Get_Proc_Info(This => To_String(LHS_Of_Assoc(This.name_part.all)), 
      Arity => Arity, Line => Ignored1, Column => Ignored2, Found => Found, Info => Info_Rec); 
   if not Found then
      Get_LC(This, Line, Column);
      Error_Msg_Prefix(Line, Column);
      put(file => standard_error, item => " Unable to find formal parameter information for procedure ");
      put(file => standard_error, item => To_String(LHS_Of_Assoc(This.name_part.all)));
      new_line(file => standard_error);
      put(file => standard_error, item => "Did you run your program through AdaGIDE first?");
      raise Parse_Error_Exception;
   end if;
   return Info_Rec.Formal_Parameters(i);
end Name_Of_Formal_As_Declared;

   procedure Add_To_Proc_Info_Table(This : in Lego_Builtins.Procedure_Info_Record_Type; Line, Column : in integer) is
   slot : integer := 0;
   begin
      for i in 1..Lego_Builtins.Max_Procedures loop
         if Lego_Builtins.Procedure_Info_Table(i).Name = To_Unbounded_String("") then
            slot := i;
            exit;
         end if;
      end loop;
   
      if slot = 0 then
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " Your program has too many procedures to be translated");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "(max is ");
         put(File => Standard_Error, Item => Lego_Builtins.Max_Procedures, Width => 0);
         put(File => Standard_Error, Item => " for Ada/Mindstorms).  Reduce the number of procedures and recompile.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      else
         Lego_Builtins.Procedure_Info_Table(slot) := This;
      end if;
   end Add_To_Proc_Info_Table;


   -----------------------
   -- Change_Identifier --
   -----------------------
   procedure Change_Identifier(This : in out Parseable_Token; From, To : in Parseable_Token_Ptr) is
   begin
      if To_Upper(This.Token_String.all) = To_Upper(From.Token_String.all) then
         This.Token_String := new String'(To.Token_String.all);
      end if;
   end Change_Identifier;

   ---------------------------------
   -- Check For Supported Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in Parseable_Token) is
   Line : Integer := This.Line;
   Column: Integer := This.Column;
   begin
      if To_Unbounded_String(To_Upper(This.Token_String.all)) /= To_Unbounded_String("LEGO") then
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " Package '");
         put(File => Standard_Error, Item => This.Token_String.all);
         put(File => Standard_Error, Item => "' is not supported by Ada/Mindstorms.");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "Currently, only the package 'lego' can be used here.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      end if;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in Parseable_Token; Line, Column : out integer) is
   begin
      Line := This.line;
      Column := This.Column;
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------
   --All tokens (keywords, identifiers, operators) translated here.
   procedure Translate (This : in out Parseable_Token) is
   ID_String : Unbounded_String;
   begin
      case This.Token_Type is
      
         --unsupported tokens
         when ABORT_TOKEN | ACCEPT_TOKEN | CHAR_LITERAL_TOKEN | 
              CONCAT_TOKEN | DECLARE_TOKEN | DIGITS_TOKEN | DO_TOKEN | DOT_TOKEN | DOUBLE_DOT_TOKEN | 
              EXCEPTION_TOKEN | EXPONENT_TOKEN | FUNCTION_TOKEN | GENERIC_TOKEN | GOTO_TOKEN | IN_TOKEN | 
              LEFT_LABEL_BRACKET_TOKEN | NEW_TOKEN | PACKAGE_TOKEN |
              PRAGMA_TOKEN | PRIVATE_TOKEN | PROTECTED_TOKEN | RAISE_TOKEN | RANGE_TOKEN | REM_TOKEN | 
              RENAMES_TOKEN | RETURN_TOKEN | REVERSE_TOKEN | SELECT_TOKEN | SEPARATE_TOKEN | SUBTYPE_TOKEN | 
              TASK_TOKEN | TICK_TOKEN | XOR_TOKEN =>
            Error_Msg_Prefix(This.Line, This.Column);
            put(File => Standard_Error, Item => "  Ada keyword/operator/literal "); 
            put(File => Standard_Error, Item => This.Token_String.all); 
            put(File => Standard_Error, Item => " not supported.");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
            
         --ignored tokens
         when ARROW_TOKEN | IS_TOKEN | NULL_TOKEN | PIPE_TOKEN | USE_TOKEN | WHEN_TOKEN | WITH_TOKEN =>
            null;
            
         --translated tokens/keywords, forced to lower case
         when AND_TOKEN =>
            put_with_space("&&");
         when ASSIGNMENT_TOKEN =>
            put_with_space("=");
         when BASED_LITERAL_TOKEN =>   --only OK if 16#xxxxxxx#
            if Element(To_Unbounded_String(This.Token_String.all),1) = '1' and 
               Element(To_Unbounded_String(This.Token_String.all),2) = '6' then
               put("0x");
               --print out everything between the #'s
               put(Slice(Source => To_Unbounded_String(This.Token_String.all), Low => 4,
                  High => Index(Source => This.Token_String.all, Pattern => "#", 
                          Going => Backward)-1));
            else
               Error_Msg_Prefix(This.Line, This.Column);
               put(File => Standard_Error, Item => ":  non-hex based literals not supported."); 
               raise Parse_Error_Exception;
            end if;
         when BEGIN_TOKEN =>
            my_new_line;
            put("{");
            Inc_Indent;  
            my_new_line;
         when CASE_TOKEN =>
            my_new_line;
            put_with_space("switch");
         when DECIMAL_LITERAL_TOKEN =>
            if Index(Source => This.Token_String.all, Pattern => ".") > 0 or 
            Index(Source => This.Token_String.all, Pattern => "E") > 0 then
               Error_Msg_Prefix(This.Line, This.Column);
               put(File => Standard_Error, 
                  Item => " floating point values/values with exponents not supported."); 
               raise Parse_Error_Exception;
            end if;
            --might contain _'s, use attribute to strip them off
            put_with_space(Integer'Value(This.Token_String.all));
         when ELSE_Token =>
            put_with_space("else");
         when ELSIF_Token =>
            put_with_space("else if");
         when END_TOKEN =>
            Dec_Indent;
            my_new_line;
            put_with_space("}");
            my_new_line;  
         when EQ_TOKEN =>
            put_with_space("==");
         when IF_Token =>
            put_with_space("if"); 
         when INEQUALITY_TOKEN =>
            put_with_space("!=");
         when MOD_TOKEN =>
            put_with_space("%");
         when NOT_TOKEN =>
            put_with_space("!");
         when OTHERS_TOKEN =>
            put_with_space("default");
         when OR_TOKEN =>
            put_with_space("||");
         when WHILE_Token =>
            put_with_space("while");
                     
         --identifiers
         when IDENTIFIER_TOKEN =>
         
            --convert to upper case because Ada is case-insensitive
            ID_String := To_Unbounded_String(To_Upper(This.Token_String.all));
            
            --check for Ada/Mindstorm identifiers, they're usually treated specially
            if Is_Ada_Mindstorms_Identifier(To_String(ID_String)) then
               Translate_Ada_Mindstorms_Identifier(To_String(ID_String));
            else   --any other identifiers get passed through (previously converted to upper case)
               put_with_space(ID_String);
            end if;
            
         when STRING_LITERAL_token =>
            Error_Msg_Prefix(This.Line, This.Column);
            put(File => Standard_Error, Item => " Ada string literals not supported.");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
            
         --anything else is passed through
         when others =>
            put_with_space(This.Token_string.all);
            
      end case;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out NUMERIC_LIT_nonterminal1) is
   begin
      Translate(This.DECIMAL_LITERAL_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out NUMERIC_LIT_nonterminal2) is
   begin
      Translate(This.BASED_LITERAL_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out CHAR_LIT_nonterminal) is
   begin
      Translate(This.CHAR_LITERAL_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out GT_GT_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out LT_LT_nonterminal) is
   begin
      Translate(This.LEFT_LABEL_BRACKET_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out GE_nonterminal) is
   begin
      Translate(This.GREATER_THAN_OR_EQUAL_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out LT_EQ_nonterminal) is
   begin
      Translate(This.LESS_THAN_OR_EQUAL_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out NE_nonterminal) is
   begin
      Translate(This.INEQUALITY_part.all);
   end Translate;

   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in CHAR_STRING_nonterminal; Line, Column : out Integer) is
   begin
      Get_LC(This.STRING_LITERAL_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out CHAR_STRING_nonterminal) is
   begin
      Translate(This.STRING_LITERAL_part.all);
   end Translate;

   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out pragma_sym_nonterminal1) is
   begin
      Translate(This.PRAGMA_part.all);   
      Translate(This.identifier_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out pragma_sym_nonterminal2) is
   begin
      Translate(This.PRAGMA_part.all);   
      Translate(This.simple_name_part.all);
      Translate(This.L_PAREN_part.all);
      Translate(This.pragma_arg_s_part.all);
      Translate(This.R_PAREN_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pragma_arg_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pragma_arg_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pragma_arg_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pragma_arg_nonterminal2) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  pragma_s_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   --empty pragma part
   procedure Translate (This : in out pragma_s_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --pragma, not supported
   procedure Change_Identifiers(This : in out  pragma_s_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out pragma_s_nonterminal2) is
   begin
      Translate(This.pragma_s_part.all);
      Translate(This.pragma_sym_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal1; Id : Parseable_Token_Ptr) return boolean is
   begin
      return Match(This.object_decl_part.all, Id);
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal1) is
   begin
      Translate(This.object_decl_part.all);   
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal2; Id : Parseable_Token_Ptr) return boolean is
   begin
      return Match(This.number_decl_part.all, Id);
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal2) is
   begin
      Translate(This.number_decl_part.all); 
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal3; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal3) is
   begin
      Translate(This.type_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal4; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal4) is
   begin
      Translate(This.subtype_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal5; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal5) is
   begin
      Translate(This.subprog_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal6; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal6) is
   begin
      Translate(This.pkg_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal7; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal7) is
   begin
      Translate(This.task_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal8; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal8) is
   begin
      Translate(This.prot_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal9; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal9) is
   begin
      Translate(This.exception_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal10; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal10) is
   begin
      Translate(This.rename_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal11; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal11) is
   begin
      Translate(This.generic_decl_part.all);
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in decl_nonterminal12; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_nonterminal12) is
   begin
      Translate(This.body_stub_part.all);
   end Translate;

   -------------------
   -- Number_Of_Vars --
   -------------------
   function Number_Of_Vars(This : in object_decl_nonterminal) return integer is
   begin
      if Is_Constant_Declaration(This) then
         return 0;
      else
         return Number_Of_Vars(This.def_id_s_part.all);
      end if;
   end Number_Of_Vars;
   
   -----------------------------
   -- Is_Constant_Declaration --
   -----------------------------
   function Is_Constant_Declaration(This : in object_decl_nonterminal) return boolean is
   begin
      return Is_Keyword_Constant(This.object_qualifier_opt_part.all);
   end Is_Constant_Declaration;
   
   ---------------------------
   -- Add_To_Object_Decl_List --
   ---------------------------
   --adds this object decl to the appropriate object decl list
   procedure Add_To_Object_Decl_List(This : in object_decl_nonterminal) is
   begin
      case Proc_Nesting_Level is
         when 1 =>   --global object_decl
            Object_Decl_Lists.AddToFront(Global_Object_Decls, This);
            --check to make sure global variable limit not exceeded
            if Number_Of_Vars(Global_Object_Decls) > Max_NQC_Global_Variables then
               put(File => Standard_Error,
                  Item => "This program has too many variables in its main procedure to fit into the RCX.");
               new_line(File => Standard_Error);
               put(File => Standard_Error,
                  Item => "Reduce the number of variables and recompile.");   
               raise Parse_Error_Exception;
            end if;
         when 2 =>   --local object decl
            Object_Decl_Lists.AddToFront(Local_Object_Decls, This);
         when others =>
            put(File => Standard_Error, 
               Item => "Internal error in translator (procedure Add_To_Object_Decl_List),");
            new_line(File => Standard_Error);
            put(File => Standard_Error, 
               Item => "please report this error to the program maintainer at your site.");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
      end case;
   end Add_To_Object_Decl_List;
   
   ---------------------------------
   -- Is_Inline_Array_Declaration --
   ---------------------------------
   function Is_Inline_Array_Declaration(This : in object_decl_nonterminal) return boolean is
   begin
      return Is_Inline_Array_Declaration(This.object_subtype_def_part.all);
   end Is_Inline_Array_Declaration;
   
   --------------------------
   -- Is_Supported_Array_Declaration --
   --------------------------
   function Is_Supported_Array_Declaration(This : in object_decl_nonterminal) return boolean is
   Line, Column : integer;
   begin
      Line := This.COLON_part.Line;  
      Column := This.COLON_part.Column;

      --check the object subtype definition first, make sure it's an array definition
      if not Is_Supported_Array_Declaration(This.object_subtype_def_part.all) then
         return false;
      
      --can't have multiple id's
      elsif Contains_Multiple_Ids(This.def_id_s_part.all) then
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " simultaneous array declarations not supported by Ada/Mindstorms.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
         return false;
      
      --can't have aliased and/or constant arrays
      elsif not Is_Empty(This.object_qualifier_opt_part.all) then
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " aliased and/or constant arrays not supported by Ada/Mindstorms.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
         return false;
      
      --can't have array initialization
      elsif not Is_Empty(This.init_opt_part.all) then
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " array initialization not supported by Ada/Mindstorms.");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "To initialize arrays, add explicit initialization code in the relevant procedure body.");
         raise Parse_Error_Exception;
         return false;

      --got this far, must be OK
      else
         return true;
      end if;

   end Is_Supported_Array_Declaration;
   
   --------------------
   -- Get_Array_Type --
   --------------------
   function Get_Array_Type (This : in object_decl_nonterminal) return array_type_nonterminal_ptr is
   begin
      return Get_Array_Type(This.object_subtype_def_part.all);
   end Get_Array_Type;
   
   --------------------------
   -- Get_First_Identifier --
   --------------------------
   function Get_First_Identifier(This : in object_decl_nonterminal) return Parseable_Token_Ptr is
   begin
      return Get_First_Identifier(This.def_id_s_part.all);
   end Get_First_Identifier;
   
   
   --need these for the function below, not automatically included in trans_model.ads
   type type_completion_nonterminal2_ptr is access all type_completion_nonterminal2'Class;
   type type_def_nonterminal4_ptr is access all type_def_nonterminal4'Class;
   -------------------------------
   -- Make_Equivalent_Type_Decl --
   -------------------------------
   --create a type_decl object equivalent to the given object_decl object
   function Make_Equivalent_Type_Decl(This : in object_decl_nonterminal) return type_decl_nonterminal_ptr is
   --need these to build the new type_decl object
   Type_Decl : type_decl_nonterminal_ptr;
   Type_Completion : type_completion_nonterminal2_ptr;
   Type_Def : type_def_nonterminal4_ptr;
   
   begin
      Type_Def := new type_def_nonterminal4;
      Type_Def.array_type_part := Get_Array_Type(This); 
      Type_Completion := new type_completion_nonterminal2;
      Type_Completion.type_def_part := type_def_nonterminal_ptr(Type_Def);
      Type_Decl := new type_decl_nonterminal;
      Type_Decl.type_completion_part := type_completion_nonterminal_ptr(Type_Completion);
      Type_Decl.identifier_part := Get_First_Identifier(This);
      return type_decl;
   end Make_Equivalent_Type_Decl;
   
   -----------
   -- Match --
   -----------
   function Match(This : in object_decl_nonterminal; Id : Parseable_Token_Ptr) return boolean is
   begin
      if In_Id_List(This.def_id_s_part.all, Id) then
         return true;
      else
         return false;
      end if;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   --constant, variable, and array declarations are parsed here
   --id1[,id2...] : [constant] subtype [:= expr] ;
   --becomes int id1[,id2...] [= expr];   if it's a variable dec, or
   --int id1[upper_bound-lower_bound+1] if an array declaration (multiple ids not allowed), or
   --#define id1 (expr) if it's a constant dec (other id's are ignored)
   procedure Translate (This : in out object_decl_nonterminal) is
   Line, Column : integer;
   Lower_Bound, Upper_Bound : simple_expression_nonterminal_ptr;
   begin
      Line := This.COLON_part.Line;  
      Column := This.COLON_part.Column;
      
      if Is_Constant_Declaration(This) then
      
         -- constants types restricted to those supported by Ada/Mindstorms
         if not Is_Supported_Predefined_Scalar_Type(This.object_subtype_def_part.all) then
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, Item => " constant type not supported by Ada/Mindstorms.  ");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
         end if;
         
         --ignore indent levels for all translations below
         if Contains_Multiple_Ids(This.def_id_s_part.all) then
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, Item => " simultaneous constant declarations not supported.");
            new_line(File => Standard_Error);
            put(File => Standard_Error, Item => "Identifiers after the first one will be ignored.  Recode with");
            new_line(File => Standard_Error);
            put(File => Standard_Error, Item => "each identifier declared individually to process all declarations.");
            raise Parse_Error_Exception;
         end if;
         new_line;   --#define must start in column 1, regardless of indenting level
         put_with_space("#define");
         Translate_First_Id(This.def_id_s_part.all);
         
         --must have an initialization expression for constant declaration
         if Is_Empty(This.init_opt_part.all) then
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, 
               Item => " constant declarations for Ada/Mindstorms require initialization with ':='.  ");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
         end if;
         
         put("(");   --add parentheses for paranoia with C-like macros
         Translate_Expression(This.init_opt_part.all);
         put(")");
         Add_To_Object_Decl_List(This);
      elsif Is_Supported_Array_Declaration(This) then
         -- if the declaration uses "array(i..j)" instead of a user-defined type, must add
         -- an equivalent type_decl to the user type list so that lower bound can be found for
         -- subsequent array referencing
         if Is_Inline_Array_Declaration(This) then
            Add_To_User_Type_List(Make_Equivalent_Type_Decl(This).all);
         end if;
         put_with_space("int"); 
         Translate(This.def_id_s_part.all);
         put("[");
         Lower_Bound := Get_Lower_Bound(This.object_subtype_def_part.all);
         Upper_Bound := Get_Upper_Bound(This.object_subtype_def_part.all);
         put("(");
         Translate(Upper_Bound.all);
         put(")"); put(" - "); put("(");
         Translate(Lower_Bound.all);
         put(")"); put(" + 1");  put(" ]");
         Translate(This.SEMICOLON_part.all);
         Add_To_Object_Decl_List(This);
      else   --must be a scalar variable declaration
         --variable types restricted to those supported by Ada/Mindstorms
         if not Is_Supported_Predefined_Scalar_Type(This.object_subtype_def_part.all) then
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, Item => " variable type not supported by Ada/Mindstorms.  ");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
         end if;
         put_with_space("int"); 
         Translate(This.def_id_s_part.all);
         --ignore the colon
         Translate(This.init_opt_part.all);
         Translate(This.SEMICOLON_part.all);
         Add_To_Object_Decl_List(This);
      end if;
      my_new_line;
   end Translate;
   
   --------------------------
   -- Get_First_Identifier --
   --------------------------
   function Get_First_Identifier(This : in def_id_s_nonterminal1) return Parseable_Token_Ptr is
   begin
      return This.def_id_part.identifier_part;
   end Get_First_Identifier;
   
   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in def_id_s_nonterminal1;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Formal_Parameter_Array(Next_Slot) := To_Unbounded_String(This.def_id_part.IDENTIFIER_part.Token_String.all);
      Next_Slot := Next_Slot + 1;
   end Build_Formal_Parameter_List;

   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in def_id_s_nonterminal1) return integer is
   begin
      return 1;
   end Get_Arity;
   
   ----------------
   -- In_Id_List --
   ----------------
   
   -- a single identifier
   function In_Id_List(This : in def_id_s_nonterminal1; Id : Parseable_Token_Ptr) return boolean is
   ID_String : Unbounded_String;
   begin
      --convert to upper case because all translated identifiers are in upper case
      ID_String := To_Unbounded_String(To_Upper(Id.Token_String.all));
      if ID_String = To_Unbounded_String(To_Upper(This.def_id_part.IDENTIFIER_part.Token_String.all)) then
         return true;
      else
         return false;
      end if;
   end In_Id_List;
   
   ---------------------------
   -- Contains_Multiple_Ids --
   ---------------------------
   
   function Contains_Multiple_Ids(This: in def_id_s_nonterminal1) return boolean is
   begin
      return false;
   end Contains_Multiple_Ids;

   --------------------
   -- Number_Of_Vars --
   --------------------
   function Number_Of_Vars(This : in def_id_s_nonterminal1) return integer is
   begin
      return Number_Of_Vars(This.def_id_part.all);
   end Number_Of_Vars;
   
   ------------------------
   -- Translate_First_Id --
   ------------------------

   procedure Translate_First_Id (This : in def_id_s_nonterminal1) is
   begin
      Translate(This.def_id_part.all);
   end Translate_First_Id;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out def_id_s_nonterminal1) is
   begin
      Translate(This.def_id_part.all);
   end Translate;
   
   ---------------------------------
   -- Translate_Formal_Parameters --
   ---------------------------------
   
   procedure Translate_Formal_Parameters (This : in out def_id_s_nonterminal1; Reference : in Boolean) is
   begin
      if Reference then
         put_with_space("int&");
      else
         put_with_space("int");
      end if;
      Translate(This.def_id_part.all);
   end Translate_Formal_Parameters;

   -------------------
   -- Number_Of_Vars --
   -------------------
   function Number_Of_Vars(This : in def_id_s_nonterminal2) return integer is
   begin
      return Number_Of_Vars(This.def_id_s_part.all) + Number_Of_Vars(This.def_id_part.all);
   end Number_Of_Vars;
   
   --------------------------
   -- Get_First_Identifier --
   --------------------------
   function Get_First_Identifier(This : in def_id_s_nonterminal2) return Parseable_Token_Ptr is
   begin
      return Get_First_Identifier(This.def_id_s_part.all);
   end Get_First_Identifier;
   
   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in def_id_s_nonterminal2;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.def_id_s_part.all, Formal_Parameter_Array, Next_Slot);
      Formal_Parameter_Array(Next_Slot) := To_Unbounded_String(This.def_id_part.IDENTIFIER_part.Token_String.all);
      Next_Slot := Next_Slot + 1;
   end Build_Formal_Parameter_List;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in def_id_s_nonterminal2) return integer is
   begin
      return Get_Arity(This.def_id_s_part.all) + 1;
   end Get_Arity;
   
   ----------------
   -- In_Id_List --
   ----------------
   
   -- multiple identifiers
   function In_Id_List(This : in def_id_s_nonterminal2; Id : Parseable_Token_Ptr) return boolean is
   ID_String : Unbounded_String;
   begin
      if In_Id_List(This.def_id_s_part.all, Id) then   --check rest of id's in list
         return true;
      else   --check this one
         --convert to upper case because all translated identifiers are in upper case
         ID_String := To_Unbounded_String(To_Upper(Id.Token_String.all));
         if ID_String = To_Unbounded_String(To_Upper(This.def_id_part.IDENTIFIER_part.Token_String.all)) then
            return true;
         else
            return false;
         end if;
      end if;
   end In_Id_List;
   
   ---------------------------
   -- Contains_Multiple_Ids --
   ---------------------------
   
   function Contains_Multiple_Ids(This: in def_id_s_nonterminal2) return boolean is
   begin
      return true;
   end Contains_Multiple_Ids;
   
   ------------------------
   -- Translate_First_Id --
   ------------------------
   procedure Translate_First_Id (This : in def_id_s_nonterminal2) is
   begin
      Translate_First_Id(This.def_id_s_part.all);
   end Translate_First_Id;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out def_id_s_nonterminal2) is
   begin
      Translate(This.def_id_s_part.all);
      Translate(This.COMMA_part.all);
      Translate(This.def_id_part.all);
   end Translate;

   procedure Translate_Formal_Parameters (This : in out def_id_s_nonterminal2; Reference : in Boolean) is
   begin
      Translate_Formal_Parameters(This.def_id_s_part.all, Reference);
      Translate(This.COMMA_part.all);
      if Reference then
         put_with_space("int&");
      else
         put_with_space("int");
      end if;
      Translate(This.def_id_part.all);
   end Translate_Formal_Parameters;
   
   -------------------
   -- Number_Of_Vars --
   -------------------
   function Number_Of_Vars(This : in def_id_nonterminal) return integer is
   begin
      return 1;
   end Number_Of_Vars;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out def_id_nonterminal) is
   Line, Column : integer;
   begin
      -- identifiers can't match anything in lego.ads, would cause translation problems
      if Is_Ada_Mindstorms_Identifier(This.IDENTIFIER_part.Token_String.all) then
         Line := This.IDENTIFIER_part.Line;
         Column := This.IDENTIFIER_part.column;
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " Identifier ");
         put(File => Standard_Error, Item => This.identifier_part.Token_String.all);
         put(File => Standard_Error, Item => " is the same name as something that is ");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "already a part of Ada/Mindstorms (look in lego.ads for details).");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "Change the name of the identifier and recompile.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      else
         Translate(This.identifier_part.all);
      end if;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in object_qualifier_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;
   -------------------------
   -- Is_Keyword_Constant --
   -------------------------
   function Is_Keyword_Constant(This: in object_qualifier_opt_nonterminal1) return boolean is
   begin
      return false;
   end Is_Keyword_Constant;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_qualifier_opt_nonterminal1) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in object_qualifier_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   -------------------------
   -- Is_Keyword_Constant --
   -------------------------
   function Is_Keyword_Constant(This: in object_qualifier_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Keyword_Constant;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_qualifier_opt_nonterminal2) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in object_qualifier_opt_nonterminal3) return boolean is
   begin
      return false;
   end Is_Empty;
   
   -------------------------
   -- Is_Keyword_Constant --
   -------------------------
   --if dispatched to here, must be the keyword 'constant'
   function Is_Keyword_Constant(This: in object_qualifier_opt_nonterminal3) return boolean is
   begin
      return true;
   end Is_Keyword_Constant;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_qualifier_opt_nonterminal3) is
   begin
      null;
   end Translate;
   
   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in object_qualifier_opt_nonterminal4) return boolean is
   begin
      return false;
   end Is_Empty;
   
   -------------------------
   -- Is_Keyword_Constant --
   -------------------------
   function Is_Keyword_Constant(This: in object_qualifier_opt_nonterminal4) return boolean is
   begin 
      return false;
   end Is_Keyword_Constant;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_qualifier_opt_nonterminal4) is
   begin
      null;
   end Translate;
   
   --------------------
   -- Get_Array_Type --
   --------------------
   --should never be called
   function Get_Array_Type(This : in object_subtype_def_nonterminal1) return array_type_nonterminal_ptr is
   begin
      return null;
   end Get_Array_Type;
   
   ---------------------------------
   -- Is_Supported_Predefined_Scalar_Type  --
   ---------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in object_subtype_def_nonterminal1) return boolean is 
   begin
      return Is_Supported_Predefined_Scalar_Type(This.subtype_ind_part.all);
   end Is_Supported_Predefined_Scalar_Type;
   
   -------------------------------------
   -- Is_Supported_User_Defined_Type  --
   -------------------------------------
   function Is_Supported_User_Defined_Type(This: in object_subtype_def_nonterminal1) return boolean is 
   begin
      return Is_Supported_User_Defined_Type(This.subtype_ind_part.all);
   end Is_Supported_User_Defined_Type;
   
   -----------------------------------------
   -- Is_Supported_Predefined_Array_Type  --
   -----------------------------------------
   function Is_Supported_Predefined_Array_Type(This : in object_subtype_def_nonterminal1) return boolean is
   begin
      return Is_Supported_Predefined_Array_Type(This.subtype_ind_part.all);
   end Is_Supported_Predefined_Array_Type;
   
   -------------------------------------
   -- Is_Supported_Array_Declaration --
   -------------------------------------
   function Is_Supported_Array_Declaration(This : in object_subtype_def_nonterminal1) return boolean is
   begin
      return (Is_Supported_User_Defined_Type(This) or Is_Supported_Predefined_Array_Type(This));
   end Is_Supported_Array_Declaration;  
 
   ---------------------------------
   -- Is_Inline_Array_Declaration --
   ---------------------------------
   function Is_Inline_Array_Declaration(This : in object_subtype_def_nonterminal1) return boolean is
   begin
      return false;
   end Is_Inline_Array_Declaration;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound (This : in object_subtype_def_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.subtype_ind_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound (This : in object_subtype_def_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.subtype_ind_part.all);
   end Get_Upper_Bound;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_subtype_def_nonterminal1) is
   begin
      Translate(This.subtype_ind_part.all);
   end Translate;

   --------------------
   -- Get_Array_Type --
   --------------------
   function Get_Array_Type(This : in object_subtype_def_nonterminal2) return array_type_nonterminal_ptr is
   begin
      return This.array_type_part;
   end Get_Array_Type;
   
   -------------------------------------
   -- Is_Supported_Array_Declaration --
   -------------------------------------
   function Is_Supported_Array_Declaration(This : in object_subtype_def_nonterminal2) return boolean is
   begin
      return Is_Supported_Array_Type(This.array_type_part.all);
   end Is_Supported_Array_Declaration;
   
   ---------------------------------
   -- Is_Inline_Array_Declaration --
   ---------------------------------
   -- yes, I know it's the same function as the one above
   function Is_Inline_Array_Declaration(This : in object_subtype_def_nonterminal2) return boolean is
   begin
      return Is_Supported_Array_Type(This.array_type_part.all);
   end Is_Inline_Array_Declaration;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound (This : in object_subtype_def_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.array_type_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound (This : in object_subtype_def_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.array_type_part.all);
   end Get_Upper_Bound;
   
   -----------------------------------
   -- Is_Supported_Predefined_Scalar_Type  --
   -----------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in object_subtype_def_nonterminal2) return boolean is 
   begin
      return Is_Supported_Array_Type(This.array_type_part.all);
   end Is_Supported_Predefined_Scalar_Type;
   
   -------------------------------------
   -- Is_Supported_User_Defined_Type  --
   -------------------------------------
   --can have arrays of predefined types only
   function Is_Supported_User_Defined_Type(This: in object_subtype_def_nonterminal2) return boolean is 
   begin
      return Is_Supported_Array_Type(This.array_type_part.all);
   end Is_Supported_User_Defined_Type;
   
   -----------------------------
   -- Is_Supported_Array_Type --
   -----------------------------
   function Is_Supported_Predefined_Array_Type(This: in object_subtype_def_nonterminal2) return boolean is
   begin
      return false;
   end;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out object_subtype_def_nonterminal2) is
   begin
      Translate(This.array_type_part.all);
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This: in init_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;
   
   --------------------------
   -- Translate_Expression --
   --------------------------
   --should never be called, but must silence the squealing compiler
   procedure Translate_Expression(This: in init_opt_nonterminal1) is
   begin
      null;
   end Translate_Expression;
   
   ---------------
   -- Translate --
   ---------------
   --could be empty, that's OK
   procedure Translate (This : in out init_opt_nonterminal1) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This: in init_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   --------------------------
   -- Translate_Expression --
   --------------------------
   procedure Translate_Expression(This: in init_opt_nonterminal2) is
   begin
      Translate(This.expression_part.all);
   end Translate_Expression;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out init_opt_nonterminal2) is
   begin
      Translate(This.ASSIGNMENT_part.all);
      Translate(This.expression_part.all);  
   end Translate;

   -----------
   -- Match --
   -----------
   function Match(This : in number_decl_nonterminal; Id : Parseable_Token_Ptr) return boolean is
   begin
      if In_Id_List(This.def_id_s_part.all, Id) then
         return true;
      else
         return false;
      end if;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out number_decl_nonterminal) is
   Line, Column : Integer;
   begin
     Line := This.COLON_part.line;
     Column := This.COLON_part.column;
     Error_Msg_Prefix(Line, Column);
     put(File => Standard_Error, Item => " Ada number declarations are not supported ");
     put(File => Standard_Error, Item=>"(missing keyword 'Integer'?).  ");
     new_line(File => Standard_Error);
     raise Parse_Error_Exception;
--     more tree here
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in type_decl_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.type_completion_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in type_decl_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.type_completion_part.all);
   end Get_Upper_Bound;
   
   ---------------------------
   -- Add_To_User_Type_List --
   ---------------------------
   --adds this type decl to the appropriate type list
   procedure Add_To_User_Type_List(This : in type_decl_nonterminal) is
   begin
      case Proc_Nesting_Level is
         when 1 =>   --global type decl
            Type_Decl_Lists.AddToFront(Global_Type_Decls, This);
         when 2 =>
            Type_Decl_Lists.AddToFront(Local_Type_Decls, This);
         when others =>
            put(File => Standard_Error, 
               Item => "Internal error in translator (procedure Add_To_User_Type_List),");
            new_line(File => Standard_Error);
            put(File => Standard_Error, 
               Item => "please report this error to the program maintainer at your site.");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
      end case;
   end;
   
   -----------------------------------
   -- Is_Supported_Type_Declaration --
   -----------------------------------
   --returns true iff the argument parses to a type declaration supported by Ada/Mindstorms
   function Is_Supported_User_Type_Declaration(This : in type_decl_nonterminal) return boolean is
   begin
      return (Is_Empty(This.discrim_part_opt_part.all) and then 
         Is_Supported_Type_Completion(This.type_completion_part.all));
   end Is_Supported_User_Type_Declaration;

   ---------------
   -- Translate --
   ---------------
   --This is a user defined type declaration.  Only arrays of supported types are allowed.
   --No translation here, just validate and then add the information to internal data structures
   --for later use when arrays are declared and referenced.
   procedure Translate (This : in out type_decl_nonterminal) is
   Line, Column : integer;
   begin
      if Is_Supported_User_Type_Declaration(This) then
         Add_To_User_Type_List(This);   
      else
         Line := This.TYPE_part.line;
         Column := This.TYPE_part.column;
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " this kind of type declaration isn't supported by Ada/Mindstorms.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      end if;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in discrim_part_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_part_opt_nonterminal1) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in discrim_part_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_part_opt_nonterminal2) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in discrim_part_opt_nonterminal3) return boolean is
   begin
      return false;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_part_opt_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_completion_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_completion_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ----------------------------------
   -- Is_Supported_Type_Completion --
   ----------------------------------
   function Is_Supported_Type_Completion(This : in type_completion_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Type_Completion;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_completion_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in type_completion_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.type_def_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in type_completion_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.type_def_part.all);
   end Get_Upper_Bound;
   
   ----------------------------------
   -- Is_Supported_Type_Completion --
   ----------------------------------
   function Is_Supported_Type_Completion(This : in type_completion_nonterminal2) return boolean is
   begin
      return Is_Supported_Type_Def(This.type_def_part.all);
   end Is_Supported_Type_Completion;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_completion_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal1) is
   begin
      null;
   end Translate;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal2) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal3) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in type_def_nonterminal4) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.array_type_part.all); 
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in type_def_nonterminal4) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.array_type_part.all);
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   --The only type_def that's supported
   function Is_Supported_Type_Def(This : in type_def_nonterminal4) return boolean is
   begin
      return Is_Supported_Array_Type(This.array_type_part.all);
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal5) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal5) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal5) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal6) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal6) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal6) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal6) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal7) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal7) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal7) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal7) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in type_def_nonterminal8) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in type_def_nonterminal8) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------
   -- Is_Supported_Type_Def --
   ---------------------------
   function Is_Supported_Type_Def(This : in type_def_nonterminal8) return boolean is
   begin
      return false;
   end Is_Supported_Type_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out type_def_nonterminal8) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subtype_decl_nonterminal) is
   begin
      Translate(This.SUBTYPE_part.all);
   end Translate;

   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   --name followed by a constraint, not supported
   function Is_Supported_User_Defined_Type(This : in subtype_ind_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_User_Defined_Type;
   
   -----------------------------
   -- Is_Supported_Array_Type --
   -----------------------------
   --name followed by a constraint, not supported
   function Is_Supported_Predefined_Array_Type(This : in subtype_ind_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Array_Type;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in subtype_ind_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.name_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in subtype_ind_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.name_part.all);
   end Get_Upper_Bound;

   ----------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   ----------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in subtype_ind_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Scalar_Type;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subtype_ind_nonterminal1) is
   begin
      Translate(This.name_part.all);
      Translate(This.constraint_part.all);  
   end Translate;

   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This : in subtype_ind_nonterminal2) return boolean is
   begin
      return Is_Supported_User_Defined_Type(This.name_part.all);
   end Is_Supported_User_Defined_Type;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in subtype_ind_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.name_part.all);
   end;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --Should never be called, satisfy the squealing compiler
   function Get_Upper_Bound(This : in subtype_ind_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.name_part.all);
   end Get_Upper_Bound;
   
   --------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   --------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in subtype_ind_nonterminal2) return boolean is
   begin
      return Is_Supported_Predefined_Scalar_Type(This.name_part.all);
   end Is_Supported_Predefined_Scalar_Type;
   
   -----------------------------
   -- Is_Supported_Array_Type --
   -----------------------------
   function Is_Supported_Predefined_Array_Type(This : in subtype_ind_nonterminal2) return boolean is
   begin
      return Is_Supported_Predefined_Array_Type(This.name_part.all);
   end Is_Supported_Predefined_Array_Type;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subtype_ind_nonterminal2) is
   begin
      Translate(This.name_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out constraint_nonterminal1) is
   begin
      Translate(This.range_constraint_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out constraint_nonterminal2) is
   begin
      Translate(This.decimal_digits_constraint_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate(This : in out decimal_digits_constraint_nonterminal) is
   begin
      Translate(This.DIGITS_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out derived_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out derived_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out derived_type_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out derived_type_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out derived_type_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_constraint_nonterminal) is
   begin
      Translate(This.RANGE_part.all);
      --more tree here
   end Translate;
   
   ----------------------------
   -- Is_Supported_Range_Sym --
   ----------------------------
   -- simple_exp .. simple_exp, the only kind of range supported
   function Is_Supported_Range_Sym(This : in range_sym_nonterminal1) return boolean is
   begin
      return true;
   end Is_Supported_Range_Sym;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   function Get_Left_Expression(This : in range_sym_nonterminal1) return
      simple_expression_nonterminal_ptr is
   begin
      return This.simple_expression_part1;
   end Get_Left_Expression;
   
   --------------------------
   -- Get_Right_Expression --
   --------------------------
  function Get_Right_Expression(This : in range_sym_nonterminal1) return
      simple_expression_nonterminal_ptr is
   begin
      return This.simple_expression_part2;
   end Get_Right_Expression;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out range_sym_nonterminal1;
      From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.simple_expression_part1.all, From => From, To => To);
      Change_Identifiers(This.simple_expression_part2.all, From => From, To => To);
   end Change_Identifiers;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in range_sym_nonterminal1; Line, Column : out Integer) is
   begin
      Line := This.DOUBLE_DOT_part.Line;
      Column := This.DOUBLE_DOT_part.Column;
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_sym_nonterminal1) is
   begin
      Translate(This.simple_expression_part1.all);
      Translate(This.DOUBLE_DOT_part.all);
      --more tree here
   end Translate;

   ----------------------------
   -- Is_Supported_Range_Sym --
   ----------------------------
   function Is_Supported_Range_Sym(This : in range_sym_nonterminal2) return boolean is
   begin
      return false;
   end Is_Supported_Range_Sym;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Left_Expression(This : in range_sym_nonterminal2) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Left_Expression;
   
   --------------------------
   -- Get_Right_Expression --
   --------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Right_Expression(This : in range_sym_nonterminal2) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Right_Expression;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --name TICK RANGE, not supported
   procedure Change_Identifiers(This : in out range_sym_nonterminal2;
      From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ------------
   -- Get_LC --
   ------------
   --should never be called, but easy enough to do
   procedure Get_LC(This : in range_sym_nonterminal2; Line, Column : out Integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_sym_nonterminal2) is
   begin
      Translate(This.name_part.all);
      Translate(This.TICK_part.all);
      --more tree here
   end Translate;

   ----------------------------
   -- Is_Supported_Range_Sym --
   ----------------------------
   function Is_Supported_Range_Sym(This : in range_sym_nonterminal3) return boolean is
   begin
      return false;
   end Is_Supported_Range_Sym;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Left_Expression(This : in range_sym_nonterminal3) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Left_Expression;
   
   --------------------------
   -- Get_Right_Expression --
   --------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Right_Expression(This : in range_sym_nonterminal3) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Right_Expression;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --name TICK RANGE L_PAREN expression R_PAREN, not supported  
   procedure Change_Identifiers(This : in out range_sym_nonterminal3;
      From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ------------
   -- Get_LC --
   ------------
   --should never be called, but easy enough to do
   procedure Get_LC(This : in range_sym_nonterminal3; Line, Column : out Integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_sym_nonterminal3) is
   begin
      Translate(This.name_part.all);
      Translate(This.TICK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out enumeration_type_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out enum_id_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out enum_id_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out enum_id_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out enum_id_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out integer_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out integer_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_spec_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_spec_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_spec_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out real_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out real_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out float_type_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out fixed_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out fixed_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in array_type_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in array_type_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   -----------------------------
   -- Is_Supported_Array_Type --
   -----------------------------
   function Is_Supported_Array_Type(This : in array_type_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Array_Type;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out array_type_nonterminal1) is
   begin
      Translate(this.unconstr_array_type_part.all);
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in array_Type_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.constr_array_type_part.all); 
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in array_type_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.constr_array_type_part.all);
   end Get_Upper_Bound;
   
   -----------------------------
   -- Is_Supported_Array_Type --
   -----------------------------
   function Is_Supported_Array_Type(This : in array_type_nonterminal2) return boolean is
   begin
      return Is_Supported_Constr_Array_Type(This.constr_array_type_part.all);
   end Is_Supported_Array_Type;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out array_type_nonterminal2) is
   begin
      Translate(This.constr_array_type_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unconstr_array_type_nonterminal) is
   begin
      Translate(This.ARRAY_part.all);
      --more tree here
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in constr_array_type_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.iter_index_constraint_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in constr_array_type_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.iter_index_constraint_part.all);
   end Get_Upper_Bound;
   
   ------------------------------------
   -- Is_Supported_Constr_Array_Type --
   ------------------------------------
   function Is_Supported_Constr_Array_Type(This : in constr_array_type_nonterminal) return boolean is
   begin
      return (Is_Supported_Iter_Index_Constraint(This.iter_index_constraint_part.all) and then
         Is_Supported_Component_Subtype_Def(This.component_subtype_def_part));
   end Is_Supported_Constr_Array_Type;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out constr_array_type_nonterminal) is
   begin
      Translate(This.ARRAY_Part.all);
      --more tree here
   end Translate;

   ----------------------------------------
   -- Is_Supported_Component_Subtype_Def --
   ----------------------------------------
   function Is_Supported_Component_Subtype_Def(This : in component_subtype_def_nonterminal_ptr) return boolean is
   begin
      return Is_Empty(This.aliased_opt_part.all) and then (Is_Supported_Predefined_Scalar_Type(This.subtype_ind_part.all));
   end Is_Supported_Component_Subtype_Def;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out component_subtype_def_nonterminal) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in aliased_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aliased_opt_nonterminal1) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in aliased_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aliased_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out index_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out index_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out index_nonterminal) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in iter_index_constraint_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.iter_discrete_range_s_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in iter_index_constraint_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.iter_discrete_range_s_part.all);
   end Get_Upper_Bound;
   
   ----------------------------------------
   -- Is_Supported_Iter_Index_Constraint --
   ----------------------------------------
   function Is_Supported_Iter_Index_Constraint(This : in iter_index_constraint_nonterminal) return boolean is
   begin
      return Is_Supported_Iter_Discrete_Range_S(This.iter_discrete_range_s_part.all);
   end Is_Supported_Iter_Index_Constraint;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out iter_index_constraint_nonterminal) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in iter_discrete_range_s_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.discrete_range_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in iter_discrete_range_s_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.discrete_range_part.all);
   end Get_Upper_Bound;
   
   ----------------------------------------
   -- Is_Supported_Iter_Discrete_Range_S --
   ----------------------------------------
   function Is_Supported_Iter_Discrete_Range_S(This: iter_discrete_range_s_nonterminal1) return boolean is
   begin
      return Is_Supported_Discrete_Range(This.discrete_range_part.all);
   end Is_Supported_Iter_Discrete_Range_S;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out iter_discrete_range_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in iter_discrete_range_s_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in iter_discrete_range_s_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   --------------------------------------
   -- Is_Supported_Iter_Discrete_Range --
   --------------------------------------
   --multidimensional arrays, not supported
   --print error message and exit
   function Is_Supported_Iter_Discrete_Range_S(This: iter_discrete_range_s_nonterminal2) return boolean is
   Line, Column : Integer;
   begin
      Get_LC(This.discrete_range_part.all, Line, Column);
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => "Ada/Mindstorms doesn't support multidimensional arrays.  You'll have to");
      new_line(File => Standard_Error);
      put(File => Standard_error, Item => "declare them separately and recompile.");
      raise Parse_Error_Exception;
      return false;   --keep compiler happy
   end Is_Supported_Iter_Discrete_Range_S;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out iter_discrete_range_s_nonterminal2) is
   begin
      null;
   end Translate;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in discrete_range_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in discrete_range_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------------------------
   -- Is_Supported_Discrete_Range --
   ---------------------------------
   --name [range constraint], this type of discrete range not supported
   function Is_Supported_Discrete_Range(This : in discrete_range_nonterminal1) return boolean is
   begin
      return false;
   end Is_Supported_Discrete_Range;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Left_Expression(This : in discrete_range_nonterminal1) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Left_Expression;
   
   -------------------------
   -- Get_Right_Expression --
   -------------------------
   --should never be called, but has to exist to keep compiler happy
   function Get_Right_Expression(This : in discrete_range_nonterminal1) return
      simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Right_Expression;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out discrete_range_nonterminal1; From, To: in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.name_part.all, From => From, To => To);
      --ignore range_constr_opt
   end Change_Identifiers;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in discrete_range_nonterminal1; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out discrete_range_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out discrete_range_nonterminal2; From, To: in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.range_sym_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in discrete_range_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Left_Expression(This.range_sym_part.all);   --just use this function, already written for other things
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in discrete_range_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Right_Expression(This.range_sym_part.all);   --just use this function, already written for other things
   end Get_Upper_Bound;
   
   ---------------------------------
   -- Is_Supported_Discrete_Range --
   ---------------------------------
   function Is_Supported_Discrete_Range(This : in discrete_range_nonterminal2) return boolean is
   begin
      return Is_Supported_Range_Sym(This.range_sym_part.all);
   end Is_Supported_Discrete_Range;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   function Get_Left_Expression(This : in discrete_range_nonterminal2) return
      simple_expression_nonterminal_ptr is
   begin
      return Get_Left_Expression(This.range_sym_part.all);
   end Get_Left_Expression;
   
   -------------------------
   -- Get_Right_Expression --
   -------------------------
  function Get_Right_Expression(This : in discrete_range_nonterminal2) return
      simple_expression_nonterminal_ptr is
   begin
      return Get_Right_Expression(This.range_sym_part.all);
   end Get_Right_Expression;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in discrete_range_nonterminal2; Line, Column : out integer) is
   begin
      Get_LC(This.range_sym_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrete_range_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_constr_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out range_constr_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out record_type_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out record_def_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out record_def_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out tagged_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out tagged_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out tagged_opt_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_list_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_list_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_list_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_decl_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_decl_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_part_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_part_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_decl_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_part_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_spec_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_spec_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrim_spec_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_part_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out variant_nonterminal) is
   begin
      null;
   end Translate;

   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This : in choice_s_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.choice_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out choice_s_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.choice_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ----------------------------------
   -- Translate_For_Case_Statement --
   ----------------------------------
   procedure Translate_For_Case_Statement(This : in choice_s_nonterminal1) is
   begin
      Translate_For_Case_Statement(This.choice_part.all);
   end Translate_For_Case_Statement;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out choice_s_nonterminal1) is
   begin
      Translate(This.choice_part.all);
   end Translate;

   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   -- should never be called
   function LHS_Of_Assoc(This : in choice_s_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out choice_s_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.choice_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.choice_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ----------------------------------
   -- Translate_For_Case_Statement --
   ----------------------------------
   procedure Translate_For_Case_Statement(This : in choice_s_nonterminal2) is
   begin
      Translate_For_Case_Statement(This.choice_s_part.all);
      Translate(This.PIPE_part.all);   --ignored
      Translate_For_Case_Statement(This.choice_part.all);
   end Translate_For_Case_Statement;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out choice_s_nonterminal2) is
   begin
      Translate(This.choice_s_part.all);
      Translate(This.PIPE_part.all);
      Translate(This.choice_part.all);
   end Translate;

   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc (This : in choice_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.expression_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out choice_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;

   ----------------------------------
   -- Translate_For_Case_Statement --
   ----------------------------------
   --"expr" becomes "case expr:"
   procedure Translate_For_Case_Statement(This : in choice_nonterminal1) is
   begin
      put_with_space("case");
      Translate(This.expression_part.all);
      put_with_space(":");
   end Translate_For_Case_Statement;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out choice_nonterminal1) is
   begin
      Translate(This.expression_part.all);
   end Translate;

   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc (This : in choice_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
  
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out choice_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.discrete_with_range_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ----------------------------------
   -- Translate_For_Case_Statement --
   ----------------------------------
   --".." in case statement, not supported
   procedure Translate_For_Case_Statement(This : in choice_nonterminal2) is
   begin
      Translate(This.discrete_with_range_part.all);
   end Translate_For_Case_Statement;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out choice_nonterminal2) is
   begin
      Translate(This.discrete_with_range_part.all);
   end Translate;

   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc (This : in choice_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --OTHERS, doesn't contain identifiers
   procedure Change_Identifiers(This : in out choice_nonterminal3;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ----------------------------------
   -- Translate_For_Case_Statement --
   ----------------------------------
   --"others" becomes "default:"
   procedure Translate_For_Case_Statement(This : in choice_nonterminal3) is
   begin
      Translate(This.OTHERS_part.all);
      put_with_space(":");
   end Translate_For_Case_Statement;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out choice_nonterminal3) is
   begin
      Translate(This.OTHERS_part.all);
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in discrete_with_range_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in discrete_with_range_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   -----------------------
   -- Change_Identifiers --
   -----------------------
   --name range_constraint, not supported
   procedure Change_Identifiers(This : in out discrete_with_range_nonterminal1;
      From, To : Parseable_Token_Ptr) is
   begin
      null;
   end;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrete_with_range_nonterminal1) is
   begin
      Translate(This.name_part.all);
      Translate(This.range_constraint_part.all);
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in discrete_with_range_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Left_Expression(This.range_sym_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in discrete_with_range_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Right_Expression(This.range_sym_part.all);
   end Get_Upper_Bound;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out discrete_with_range_nonterminal2;
      From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.range_sym_part.all, From => From, To => To);
   end;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out discrete_with_range_nonterminal2) is
   begin
      Translate(This.range_sym_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_type_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_type_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out access_type_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_opt_nonterminal2) is
   begin
      null;
   end Translate;

   -----------------------
   -- Search_And_Insert --
   -----------------------
   --decl section is empty, must build a new one in the calling procedure
   procedure Search_And_Insert(This : in out decl_part_nonterminal1; Id : Parseable_Token_Ptr; 
      Result : out Decl_Search_Result_Type) is
   begin
      Result := Decls_Are_Empty;
   end Search_And_Insert;
   
   ------------------------------
   -- Create_Unique_Identifier --
   ------------------------------
   procedure Create_And_Add_Unique_Identifier(This: in out decl_part_nonterminal1; Unique_Id : out Parseable_Token_Ptr) is
   begin
      This := This;   --silence the squealing compiler
      Unique_Id := Unique_Id;   
   end Create_And_Add_Unique_Identifier;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_part_nonterminal1) is
   begin
      null;
   end Translate;

   --need some access types not automatically included in trans_model.ads
   type def_id_s_nonterminal1_ptr is access all def_id_s_nonterminal1'Class;
   type name_nonterminal1_ptr is access all name_nonterminal1'Class;
   type subtype_ind_nonterminal2_ptr is access all subtype_ind_nonterminal2'Class;
   type object_subtype_def_nonterminal1_ptr is access all object_subtype_def_nonterminal1'Class;
   type object_qualifier_opt_nonterminal1_ptr is access all object_qualifier_opt_nonterminal1'Class;
   type init_opt_nonterminal1_ptr is access all init_opt_nonterminal1'Class;
   
   --construct new piece of the tree for "id : integer ;"
   function Make_Object_Decl(Id : in Parseable_Token_Ptr) return object_decl_nonterminal_ptr is
   New_Def_Id : def_id_nonterminal_ptr;
   New_Def_Id_S : def_id_s_nonterminal1_Ptr;
   New_Simple_Name : simple_name_nonterminal_ptr;
   New_Name : name_nonterminal1_ptr;
   New_Subtype_Ind : subtype_ind_nonterminal2_ptr;
   New_Object_Subtype_Def : object_subtype_def_nonterminal1_ptr;
   New_Object_Decl : object_decl_nonterminal_ptr;
   Colon_Tkn, Integer_Tkn, Semicolon_Tkn : Parseable_Token_Ptr;
   begin
      New_Object_Decl := new object_decl_nonterminal; --pointer to object we'll be returning
      
      --build from bottom up
      New_Def_Id := new def_id_nonterminal;
      New_Def_Id.Identifier_part := Id;
      New_Def_Id_S := new def_id_s_nonterminal1; 
      New_Def_Id_S.def_id_part := New_Def_Id;
      New_Object_Decl.def_id_s_part := def_id_s_nonterminal_ptr(New_Def_Id_S);
      
      --add the colon
      Colon_Tkn := new Parseable_Token;
      Colon_Tkn.Line := 0;
      Colon_Tkn.Column := 0;   --not worth it to set these to correct values
      Colon_Tkn.Token_String := new String'(":");
      Colon_Tkn.Token_Type := Colon_Token;
      New_Object_Decl.COLON_part := Colon_Tkn;
      
      --no qualifier, must be nonterminal1 since that's the empty version
      New_Object_Decl.object_qualifier_opt_part := new object_qualifier_opt_nonterminal1;
      
      --add the "Integer" keyword
      Integer_Tkn := new Parseable_Token;
      Integer_Tkn.Line := 0;
      Integer_Tkn.Column := 0;
      Integer_Tkn.Token_String := new String'("Integer");
      Integer_Tkn.Token_Type := Identifier_Token;
      New_Simple_Name := new simple_name_nonterminal;
      New_Simple_Name.IDENTIFIER_part := Integer_Tkn;
      New_Name := new name_nonterminal1;
      New_Name.simple_name_part := New_Simple_Name;
      New_Subtype_Ind := new subtype_ind_nonterminal2;
      New_Subtype_Ind.name_part := name_nonterminal_ptr(New_Name);
      New_Object_Subtype_Def := new object_subtype_def_nonterminal1;
      New_Object_Subtype_Def.subtype_ind_part := subtype_ind_nonterminal_ptr(New_Subtype_Ind);
      New_Object_Decl.object_subtype_def_part := object_subtype_def_nonterminal_ptr(New_Object_Subtype_Def);
      
      --no initialization, must be nonterminal1 since that's the empty version
      New_Object_Decl.init_opt_part := new init_opt_nonterminal1;
      
      --add the semicolon
      Semicolon_Tkn := new Parseable_Token;
      Semicolon_Tkn.Line := 0;
      Semicolon_Tkn.Column := 0;
      Semicolon_Tkn.Token_String := new String'(";");
      Semicolon_Tkn.Token_Type := Semicolon_Token;
      New_Object_Decl.SEMICOLON_part := SEMICOLON_Tkn;
      
      --all done!
      return New_Object_Decl;
      
   end Make_Object_Decl;
   
   --need new pointer types not automatically included in trans_model.ads
   type decl_item_or_body_s1_nonterminal2_ptr is access all decl_item_or_body_s1_nonterminal2'Class;
   type decl_item_or_body_nonterminal2_ptr is access all decl_item_or_body_nonterminal2'Class;
   type decl_item_nonterminal1_ptr is access all decl_item_nonterminal1'Class;
   type decl_nonterminal1_ptr is access all decl_nonterminal1'Class;
   
   ------------------------------
   -- Create_Unique_Identifier --
   ------------------------------
   --creates a unique identifier within indicated scope, adds it to the decl block, returns it in 2nd parameter
   procedure Create_And_Add_Unique_Identifier(This: in out decl_part_nonterminal2; Unique_Id: out Parseable_Token_Ptr) is
   counter : integer := 0;
   Search_Result : Decl_Search_Result_Type;
   This2 : decl_part_nonterminal2 := This;   --because actual in call to Search_And_Insert must be a variable
   Suffix : Unbounded_String;
   begin
      Unique_Id := new Parseable_Token;
      Unique_Id.Line := 0;   --not worth it to set these to their correct values
      Unique_Id.Column := 0;
      Unique_Id.Token_Type := Identifier_Token;
      loop
         Suffix := To_Unbounded_String(Integer'image(counter));
         --watch out, 'image produces a leading space
         Suffix := To_Unbounded_String(Slice(Source => Suffix, Low => 2, High => Length(Suffix)));
         Unique_Id.Token_String := new String'("i" & To_String(Suffix));
         Search_And_Insert(This2, Unique_Id, Search_Result);
         exit when Search_Result = Added_To_Decls;  
         counter := counter + 1;   --limited to 2^32 unique identifiers :-)
      end loop;
      This := This2;
   end Create_And_Add_Unique_Identifier;
   
   -----------------------
   -- Search_And_Insert --
   -----------------------
   procedure Search_And_Insert(This : in out decl_part_nonterminal2; Id : Parseable_Token_Ptr;
      Result : out Decl_Search_Result_Type) is

   Search_Result : Decl_Search_Result_Type;
   New_Decl_Item_Or_Body : decl_item_or_body_nonterminal2_ptr;
   New_Decl_Item_Or_Body_s1 : decl_item_or_body_s1_nonterminal2_ptr;
   New_Decl_Item : decl_item_nonterminal1_ptr;
   New_Decl : decl_nonterminal1_ptr;
   New_Object_Decl : object_decl_nonterminal_ptr;
   begin
      Search_Result := Not_Found_In_Decls;  
      Search(This.decl_item_or_body_s1_part.all, Id, Search_Result);
      if Search_Result = Found_In_Decls then
         Result := Found_In_Decls;
      else   --replace tree with the same one plus new identifier
         New_Object_Decl := Make_Object_Decl(Id);   --build from the bottom up
         New_Decl := new decl_nonterminal1;
         New_Decl.object_decl_part := New_Object_Decl;
         New_Decl_Item := new decl_item_nonterminal1;
         New_Decl_Item.decl_part := decl_nonterminal_ptr(New_Decl);
         New_Decl_Item_Or_Body := new decl_item_or_body_nonterminal2;
         New_Decl_Item_Or_Body.decl_item_part := decl_item_nonterminal_ptr(New_Decl_Item);
         New_Decl_Item_Or_Body_s1 := new decl_item_or_body_s1_nonterminal2;
         New_Decl_Item_Or_Body_s1.decl_item_or_body_part := decl_item_or_body_nonterminal_ptr(New_Decl_Item_Or_Body);
         New_Decl_Item_Or_Body_s1.decl_item_or_body_s1_part := This.decl_item_or_body_s1_part;   --save old tree
         This.decl_item_or_body_s1_part := decl_item_or_body_s1_nonterminal_ptr(New_Decl_Item_Or_Body_S1);  --add new piece
         Result := Added_To_Decls;
      end if;
   end Search_And_Insert;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_part_nonterminal2) is
   begin
      Translate(This.decl_item_or_body_s1_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_s1_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_s1_nonterminal2) is
   begin
      null;
   end Translate;
   
   -------------
   -- Match --
   -------------

   function Match(This : in decl_item_nonterminal1; Id : Parseable_Token_Ptr) return boolean is
   begin
      return Match(This.decl_part.all, Id);
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_nonterminal1) is
   begin
      Translate(This.decl_part.all);
   end Translate;

   -------------
   -- Match --
   -------------

   function Match(This : in decl_item_nonterminal2; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_nonterminal2) is
   begin
      Translate(This.use_clause_part.all);
   end Translate;

   -------------
   -- Match --
   -------------

   function Match(This : in decl_item_nonterminal3; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_nonterminal3) is
   begin
      Translate(This.rep_spec_part.all);
   end Translate;

   -------------
   -- Match --
   -------------

   function Match(This : in decl_item_nonterminal4; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_nonterminal4) is
   begin
      Translate(This.pragma_sym_part.all);
   end Translate;

   -------------
   -- Search --
   -------------
   
   procedure Search(This : in decl_item_or_body_s1_nonterminal1; Id : Parseable_Token_Ptr;
      Result : out Decl_Search_Result_Type) is
   begin
      if Match(This.decl_item_or_body_part.all, Id) then
         Result := Found_In_Decls;
      else
         Result := Not_Found_In_Decls;
      end if;
   end Search;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_or_body_s1_nonterminal1) is
   begin
      Translate(This.decl_item_or_body_part.all);
   end Translate;

   -------------
   -- Search --
   -------------
   
   procedure Search(This : in decl_item_or_body_s1_nonterminal2; Id : Parseable_Token_Ptr;
      Result : out Decl_Search_Result_Type) is
   begin
      Search(This.decl_item_or_body_s1_part.all, Id, Result);   --check rest of decl tree
      if Result = Not_Found_In_Decls then   --check this entry
         if Match(This.decl_item_or_body_part.all, Id) then
            Result := Found_In_Decls;
         end if;
      end if;
   end Search;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_or_body_s1_nonterminal2) is
   begin
      Translate(This.decl_item_or_body_s1_part.all);
      Translate(This.decl_item_or_body_part.all);
   end Translate;

   -------------
   -- Search --
   -------------
   --points to a body, can't contain what we're looking for
   function Match(This : in decl_item_or_body_nonterminal1; Id : Parseable_Token_Ptr) return boolean is
   begin
      return false;
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_or_body_nonterminal1) is
   begin
      Translate(This.body_nt_part.all);
   end Translate;

   -------------
   -- Match --
   -------------
   --points to a decl_item
   function Match(This : in decl_item_or_body_nonterminal2; Id : Parseable_Token_Ptr) return boolean is
   begin
      return Match(This.decl_item_part.all, Id);
   end Match;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out decl_item_or_body_nonterminal2) is
   begin
      Translate(This.decl_item_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_nt_nonterminal1) is
   begin
      Translate(This.subprog_body_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_nt_nonterminal2) is
   begin
      Translate(This.pkg_body_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_nt_nonterminal3) is
   begin
      Translate(This.task_body_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_nt_nonterminal4) is
   begin
      Translate(This.prot_body_part.all);
   end Translate;

   ----------------------------
   -- Get_Object_Subtype_Def --
   ----------------------------
   -- find the object subtype def associated with this variable in the appropriate list and return it
   
   --MODIFIED 10-10-05 BY BSF TO SUPPORT ARRAYS WITH GLOBAL SCOPE.  MODIFICATION
   --SUGGESTED BY EMILY BRAUNSTEIN AT DRAPER LABS.  POC IS djohnson@draper.com.
   
   function Get_Object_Subtype_Def(This : in name_nonterminal1) return object_subtype_def_nonterminal_ptr is
   Decl : object_decl_nonterminal;
   ID_String : Unbounded_String;
   Current : Object_Decl_Lists.Position;
   Line, Column : integer;
   begin

      ID_String := To_Unbounded_String(To_Upper(This.simple_name_part.identifier_part.Token_String.all));
      --search the appropriate object decl list
      if Proc_Nesting_level = 1 then
         Current := Object_Decl_Lists.First(Global_Object_Decls);
         while not Object_Decl_Lists.IsPastEnd(Global_Object_Decls, Current) loop
            Decl := Object_Decl_Lists.Retrieve(Global_Object_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Get_First_Identifier(Decl.def_id_s_part.all).Token_String.all)) = ID_String then
               return Decl.object_subtype_def_part;
            end if;
            Object_Decl_Lists.GoAhead(Global_Object_Decls, Current);
         end loop;
      elsif Proc_Nesting_Level = 2 then
         Current := Object_Decl_Lists.First(Local_Object_Decls);
         while not Object_Decl_Lists.IsPastEnd(Local_Object_Decls, Current) loop
            Decl := Object_Decl_Lists.Retrieve(Local_Object_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Get_First_Identifier(Decl.def_id_s_part.all).Token_String.all)) = ID_String then
               return Decl.object_subtype_def_part;
            end if;
            Object_Decl_Lists.GoAhead(Local_Object_Decls, Current);
         end loop;
         Current := Object_Decl_Lists.First(Global_Object_Decls);
         while not Object_Decl_Lists.IsPastEnd(Global_Object_Decls, Current) loop
            Decl := Object_Decl_Lists.Retrieve(Global_Object_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Get_First_Identifier(Decl.def_id_s_part.all).Token_String.all)) = ID_String then
               return Decl.object_subtype_def_part;
            end if;
            Object_Decl_Lists.GoAhead(Global_Object_Decls, Current);
         end loop;         
      else
          put(File => Standard_Error, 
             Item => "Internal error in translator (procedure Get_Object_Subtype_Def(simple_name_nonterminal)),");
          new_line(File => Standard_Error);
          put(File => Standard_Error, 
             Item => "please report this error to the program maintainer at your site.");
          new_line(File => Standard_Error);
          raise Parse_Error_Exception;
          return null;
      end if;
      --if you got this far, didn't find it, must be a problem
      Line := This.simple_name_part.identifier_part.LINE;
      Column := This.simple_name_part.identifier_part.COLUMN;
      Error_Msg_Prefix(Line, Column);
      put(file => standard_error, item => " Unable to find type for variable ");
      put(file => standard_error, item => To_Upper(This.simple_name_part.identifier_part.Token_String.all));
      new_line(file => standard_error);
      put(file => standard_error, item => "Did you run your program through AdaGIDE first?");
      new_line(file => standard_error);
      raise Parse_Error_Exception;
      return null;
   end Get_Object_Subtype_Def;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in name_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.simple_name_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in name_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.simple_name_part.all);
   end Get_Upper_Bound;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in name_nonterminal1) return integer is
   begin
      return Get_Arity(This.simple_name_part.all);
   end Get_Arity;
   
   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in name_nonterminal1) return boolean is
   begin
      return Is_Constant(This.simple_name_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in name_nonterminal1) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.simple_name_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in name_nonterminal1) return boolean is
   begin
      return Is_Identifier(This.simple_name_part.all);
   end Is_Identifier;
   
   --------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   --------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in name_nonterminal1) return boolean is
   begin
      return Is_Supported_Predefined_Scalar_Type(This.simple_name_part.all);
   end Is_Supported_Predefined_Scalar_Type;
   
   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type(This: in name_nonterminal1) return boolean is
   begin
      return Is_Supported_Predefined_Array_Type(This.simple_name_part.all);
   end Is_Supported_Predefined_Array_Type;
   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This: in name_nonterminal1) return boolean is
   begin
      return Is_Supported_User_Defined_Type(This.simple_name_part.all);
   end Is_Supported_User_Defined_Type;
     
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   function LHS_Of_Assoc(This : in name_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.simple_name_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  name_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_name_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in name_nonterminal1) is
   begin
      Check_For_Supported_Package(This.simple_name_part.all);
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in name_nonterminal1; Line, Column : out integer) is
   begin
      Get_LC(This.simple_name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_nonterminal1) is
   begin
      Translate(This.simple_name_part.all);   
   end Translate;
   
   ----------------------------
   -- Get_Object_Subtype_Def --
   ----------------------------
   -- should never be called
   function Get_Object_Subtype_Def(This : in name_nonterminal2) return object_subtype_def_nonterminal_ptr is
   begin
      return null;
   end Get_Object_Subtype_Def;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in name_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.indexed_comp_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in name_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.indexed_comp_part.all);
   end Get_Upper_Bound;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in name_nonterminal2) return integer is
   begin
      return Get_Arity(This.indexed_comp_part.all);
   end Get_Arity;
   
   -----------------
   -- Is_Constant --
   -----------------
   --indexed component (procedure call, function call, or array reference)
   --currently none of the these can be constants
   function Is_Constant(This : in name_nonterminal2) return boolean is
   begin
      return false;
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in name_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in name_nonterminal2) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ----------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   ----------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in name_nonterminal2) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Scalar_Type;
   
   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type(This: in name_nonterminal2) return boolean is
   begin
      return Is_Supported_Predefined_Array_Type(This.indexed_comp_part.all);
   end Is_Supported_Predefined_Array_Type;   
   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This: in name_nonterminal2) return boolean is
   begin
      return false;
   end Is_Supported_User_Defined_Type;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in name_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  name_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.indexed_comp_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   -- should never be called
   procedure Check_For_Supported_Package(This : in name_nonterminal2) is
   begin
      null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in name_nonterminal2; Line, Column : out integer) is
   begin
      Get_LC(This.indexed_comp_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out name_nonterminal2) is
   begin
      Translate(This.indexed_comp_part.all);
   end Translate;
   
   ----------------------------
   -- Get_Object_Subtype_Def --
   ----------------------------
   -- should never be called
   function Get_Object_Subtype_Def(This : in name_nonterminal3) return object_subtype_def_nonterminal_ptr is
   begin
      return null;
   end Get_Object_Subtype_Def;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in name_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in name_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------
   -- Get_Arity --
   ---------------
   --should never be called
   function Get_Arity(This : in name_nonterminal3) return integer is
   begin
      return -1;
   end Get_Arity;
   
   -----------------
   -- Is_Constant --
   -----------------
   --selected comp
   function Is_Constant(This : in name_nonterminal3) return boolean is
   begin
      return false;
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in name_nonterminal3) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in name_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ----------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   ----------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in name_nonterminal3) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Scalar_Type;
   
   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type(This: in name_nonterminal3) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Array_Type;   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This: in name_nonterminal3) return boolean is
   begin
      return false;
   end Is_Supported_User_Defined_Type;
   
   --------------------------------
   -- Is_Supported_Variable_Type --
   --------------------------------
   function Is_Supported_Variable_Type(This: in name_nonterminal3) return boolean is
   ignored : name_nonterminal3;
   begin
      ignored := This;   --this code suppresses a "This is not referenced" warning
      return false;
   end Is_Supported_Variable_Type;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in name_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in name_nonterminal3) is
   begin
      Check_For_Supported_Package(This.selected_comp_part.all);
   end Check_For_Supported_Package;
      
   ------------------------
   -- Change_Identifiers --
   ------------------------
   -- selected_comp, not currently supported
   procedure change_identifiers(This : in out  name_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in name_nonterminal3; Line, Column : out integer) is
   begin
      Get_LC(This.selected_comp_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_nonterminal3) is
   begin
      Translate(This.selected_comp_part.all);
   end Translate;
   
   ----------------------------
   -- Get_Object_Subtype_Def --
   ----------------------------
   -- should never be called
   function Get_Object_Subtype_Def(This : in name_nonterminal4) return object_subtype_def_nonterminal_ptr is
   begin
      return null;
   end Get_Object_Subtype_Def;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in name_nonterminal4) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in name_nonterminal4) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------
   -- Get_Arity --
   ---------------
   --should never be called
   function Get_Arity(This : in name_nonterminal4) return integer is
   begin
      return -1;
   end Get_Arity;
   
   -----------------
   -- Is_Constant --
   -----------------
   --attribute
   function Is_Constant(This : in name_nonterminal4) return boolean is
   begin
      return false;
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in name_nonterminal4) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in name_nonterminal4) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ----------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   ----------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in name_nonterminal4) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Scalar_Type;
   
   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type(This: in name_nonterminal4) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Array_Type;
   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This: in name_nonterminal4) return boolean is
   begin
      return false;
   end Is_Supported_User_Defined_Type;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in name_nonterminal4) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
      
   ------------------------
   -- Change_Identifiers --
   ------------------------
   --attribute, not currently supported
   procedure change_identifiers(This : in out  name_nonterminal4; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   --should never be called
   procedure Check_For_Supported_Package(This : in name_nonterminal4) is
   begin
      null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in name_nonterminal4; Line, Column : out integer) is
   begin
      Get_LC(This.attribute_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_nonterminal4) is
   begin
      Translate(This.attribute_part.all);
   end Translate;
   
   ----------------------------
   -- Get_Object_Subtype_Def --
   ----------------------------
   -- should never be called
   function Get_Object_Subtype_Def(This : in name_nonterminal5) return object_subtype_def_nonterminal_ptr is
   begin
      return null;
   end Get_Object_Subtype_Def;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --should never be called
   function Get_Lower_Bound(This : in name_nonterminal5) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --should never be called
   function Get_Upper_Bound(This : in name_nonterminal5) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   ---------------
   -- Get_Arity --
   ---------------
   --should never be called
   function Get_Arity(This : in name_nonterminal5) return integer is
   begin
      return -1;
   end Get_Arity;
   
   -----------------
   -- Is_Constant --
   -----------------
   --operator symbol -> char_string -> string_literal, that's a constant
   function Is_Constant(This : in name_nonterminal5) return boolean is
   begin
      return true;
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in name_nonterminal5) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in name_nonterminal5) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   -----------------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   -----------------------------------------
   function Is_Supported_Predefined_Scalar_Type(This: in name_nonterminal5) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Scalar_Type;
   
   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type(This: in name_nonterminal5) return boolean is
   begin
      return false;
   end Is_Supported_Predefined_Array_Type;
   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This: in name_nonterminal5) return boolean is
   begin
      return false;
   end Is_Supported_User_Defined_Type;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in name_nonterminal5) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
      
   ------------------------
   -- Change_Identifiers --
   ------------------------
   --operator symbol, not currently supported
   procedure change_identifiers(This : in out  name_nonterminal5; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   --should never be called
   procedure Check_For_Supported_Package(This : in name_nonterminal5) is
   begin
      null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in name_nonterminal5; Line, Column : out integer) is
   begin
      Get_LC(This.operator_symbol_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_nonterminal5) is
   begin
      Translate(This.operator_symbol_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mark_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mark_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mark_nonterminal3) is
   begin
      null;
   end Translate;
   
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in simple_name_nonterminal) return Parseable_Token_Ptr is
   begin
      return This.Identifier_part;
   end Get_Identifier;
   
   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant (This : in simple_name_nonterminal) return boolean is
   ID: Unbounded_String := To_Unbounded_String(This.identifier_part.Token_String.all);
   begin
      if Is_Ada_Mindstorms_Identifier(To_String(ID)) then
         return true;
      elsif Is_Global_Constant(ID) then
         return true;
      elsif Proc_Nesting_Level > 1 and Is_Local_Constant(ID) then
         return true;
      else
         return false;
      end if;
   end Is_Constant;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in simple_name_nonterminal) return boolean is
   begin
      return true;
   end Is_Identifier;
   
   ------------------------
   -- Is_Keyword_Integer --
   ------------------------
   function Is_Keyword_Integer(This : in simple_name_nonterminal) return boolean is
   ID_String : Unbounded_String;
   begin
      ID_String := To_Unbounded_String(To_Upper(This.identifier_part.Token_String.all));
      return (ID_String = To_String("INTEGER"));
   end Is_Keyword_Integer;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   --Find the type declaration associated with this type and return the lower bound
   --If not found, return null.  This could happen if the name is a procedure or function call
   function Get_Lower_Bound(This : in simple_name_nonterminal) return simple_expression_nonterminal_ptr is
   ID_String : Unbounded_String;
   Current : Type_Decl_Lists.Position;
   Decl : Type_Decl_nonterminal;
   Line, Column : integer;
   begin
      ID_String := To_Unbounded_String(To_Upper(This.identifier_part.Token_String.all));
      --search the appropriate type decl list
      if Proc_Nesting_level = 1 then
         Current := Type_Decl_Lists.First(Global_Type_Decls);
         while not Type_Decl_Lists.IsPastEnd(Global_Type_Decls, Current) loop
            Decl := Type_Decl_Lists.Retrieve(Global_Type_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Decl.identifier_part.Token_String.all)) = ID_String then
               return Get_Lower_Bound(Decl);
            end if;
            Type_Decl_Lists.GoAhead(Global_Type_Decls, Current);
         end loop;
      elsif Proc_Nesting_Level = 2 then
         Current := Type_Decl_Lists.First(Local_Type_Decls);
         while not Type_Decl_Lists.IsPastEnd(Local_Type_Decls, Current) loop
            Decl := Type_Decl_Lists.Retrieve(Local_Type_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Decl.identifier_part.Token_String.all)) = ID_String then
               return Get_Lower_Bound(Decl);
            end if;
            Type_Decl_Lists.GoAhead(Local_Type_Decls, Current);
         end loop;
      else
          put(File => Standard_Error, 
             Item => "Internal error in translator (procedure Get_Lower_Bound(simple_name_nonterminal)),");
          new_line(File => Standard_Error);
          put(File => Standard_Error, 
             Item => "please report this error to the program maintainer at your site.");
          new_line(File => Standard_Error);
          raise Parse_Error_Exception;
          return null;
      end if;
      --if you got this far, didn't find it, must be a problem
      Line := This.identifier_part.LINE;
      Column := This.identifier_part.COLUMN;
      Error_Msg_Prefix(Line, Column);
      put(file => standard_error, item => " Unable to find description of user defined type ");
      put(file => standard_error, item => This.identifier_part.Token_String.all);
      new_line(file => standard_error);
      put(file => standard_error, item => "Did you run your program through AdaGIDE first?");
      new_line(file => standard_error);
      raise Parse_Error_Exception;
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   --Find the type declaration associated with this type and return the upper bound
   --should probably combine this with Get_Lower_Bound into a single function with another parameter at some point
   function Get_Upper_Bound(This : in simple_name_nonterminal) return simple_expression_nonterminal_ptr is
   ID_String : Unbounded_String;
   Current : Type_Decl_Lists.Position;
   Decl : Type_Decl_nonterminal;
   Line, Column : integer;
   begin
      ID_String := To_Unbounded_String(To_Upper(This.identifier_part.Token_String.all));
      --search the appropriate type decl list
      if Proc_Nesting_level = 1 then
         Current := Type_Decl_Lists.First(Global_Type_Decls);
         while not Type_Decl_Lists.IsPastEnd(Global_Type_Decls, Current) loop
            Decl := Type_Decl_Lists.Retrieve(Global_Type_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Decl.identifier_part.Token_String.all)) = ID_String then
               return Get_Upper_Bound(Decl);
            end if;
            Type_Decl_Lists.GoAhead(Global_Type_Decls, Current);
         end loop;
      elsif Proc_Nesting_Level = 2 then
         Current := Type_Decl_Lists.First(Local_Type_Decls);
         while not Type_Decl_Lists.IsPastEnd(Local_Type_Decls, Current) loop
            Decl := Type_Decl_Lists.Retrieve(Local_Type_Decls, Current);
            --Is this the right one?
            if To_Unbounded_String(To_Upper(Decl.identifier_part.Token_String.all)) = ID_String then
               return Get_Upper_Bound(Decl);
            end if;
            Type_Decl_Lists.GoAhead(Local_Type_Decls, Current);
         end loop;     
      else
          put(File => Standard_Error, 
             Item => "Internal error in translator (procedure Get_Upper_Bound(simple_name_nonterminal)),");
          new_line(File => Standard_Error);
          put(File => Standard_Error, 
             Item => "please report this error to the program maintainer at your site.");
          new_line(File => Standard_Error);
          raise Parse_Error_Exception;
      end if;
      --if you got this far, didn't find it, must be a problem
      Line := This.identifier_part.LINE;
      Column := This.identifier_part.COLUMN;
      Error_Msg_Prefix(Line, Column);
      put(file => standard_error, item => " Unable to find description of user defined type ");
      put(file => standard_error, item => This.identifier_part.Token_String.all);
      new_line(file => standard_error);
      put(file => standard_error, item => "Did you run your program through AdaGIDE first?");
      new_line(file => standard_error);
      raise Parse_Error_Exception;
      return null;
   end Get_Upper_Bound;

   ---------------
   -- Get_Arity --
   ---------------
   -- A simple name has no arguments, so return 0
   function Get_Arity(This : in simple_name_nonterminal) return integer is
   begin
      return 0;
   end Get_Arity;
   
   ------------------------------------
   -- Is_Supported_User_Defined_Type --
   ------------------------------------
   function Is_Supported_User_Defined_Type(This : in simple_name_nonterminal) return boolean is
   begin
      --we'll allow any name for a user-defined type that isn't reserved by Ada/Mindstorms
      if not Is_Supported_Predefined_Scalar_Type(This) then
         return true;
      else
         return false;
      end if;
   end Is_Supported_User_Defined_Type;
   
   --------------------------------
   -- Is_Supported_Predefined_Scalar_Type --
   --------------------------------
   --must be kept consistent with types in lego.ads
   function Is_Supported_Predefined_Scalar_Type(This: in simple_name_nonterminal) return boolean is
   ID_String : Unbounded_String;
   begin
      ID_String := To_Unbounded_String(To_Upper(This.identifier_part.Token_String.all));
      if ID_String = To_String("INTEGER") or
      ID_String = To_String("BOOLEAN") or
      ID_String = To_String("SENSOR_PORT") or
      ID_String = To_String("OUTPUT_PORT") or
      ID_String = To_String("OUTPUT_PORT_NUMBER") or
      ID_String = To_String("CONFIGURATION") or
      ID_String = To_String("OUTPUT_MODE") or
      ID_String = To_String("OUTPUT_DIRECTION") or
      ID_String = To_String("SENSOR_TYPE") or
      ID_String = To_String("POWER_TYPE") or
      ID_String = To_String("TRANSMITTER_POWER_SETTING") or
      ID_String = To_String("SOUND") or
      ID_String = To_String("MESSAGE") or
      ID_String = To_String("HOUR") or
      ID_String = To_String("MINUTE") or
      ID_String = To_String("DATALOG_RANGE") or
      ID_String = To_String("DURATION") or
      ID_String = To_String("FREQUENCY") or
      ID_String = To_String("SENSOR_VALUE") or
      ID_String = To_String("SENSOR_MODE") or
      ID_String = To_String("TIMER") or
      ID_String = To_String("DECIMAL_PLACE_VALUE") or
      ID_String = To_String("WATCH_VALUE_IN_MINUTES") then
         return true;
      else
         return false;
      end if;
   end Is_Supported_Predefined_Scalar_Type;


   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   --must be kept consistent with predefined array types in lego.ads
   function Is_Supported_Predefined_Array_Type(This: in simple_name_nonterminal) return boolean is
   ID_String : Unbounded_String;
   begin
      ID_String := To_Unbounded_String(To_Upper(This.identifier_part.Token_String.all));
      if ID_String = To_String("INTEGER_ARRAY") then
         return true;
      else
         return false;
      end if;
   end Is_Supported_Predefined_Array_Type;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_identifiers(This : in out  simple_name_nonterminal; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifier(This => This.IDENTIFIER_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in simple_name_nonterminal) is
   begin
      Check_For_Supported_Package(This.IDENTIFIER_part.all);
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in simple_name_nonterminal; Line, Column : out integer) is
   begin
      Get_LC(This.identifier_part.all, Line, Column);
   end Get_LC;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   function LHS_Of_Assoc(This : in simple_name_nonterminal) return Unbounded_String is
   begin
      return To_Unbounded_String(This.identifier_part.Token_String.all);
   end LHS_Of_Assoc;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_name_nonterminal) is
   begin
      Translate(This.identifier_part.all);
   end Translate;

   ---------------------
   -- Get_Simple_Name --
   ---------------------

   function Get_Simple_Name (This : in compound_name_nonterminal1) return Parseable_Token_Ptr is
   begin
      return(This.simple_name_part.Identifier_part);
   end Get_Simple_Name;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in compound_name_nonterminal1) is
   begin
      Check_For_Supported_Package(This.simple_name_part.all);
   end Check_For_Supported_Package;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compound_name_nonterminal1) is
   begin
      Translate(This.simple_name_part.all);
   end Translate;

   ---------------------
   -- Get_Simple_Name --
   ---------------------

   function Get_Simple_Name (This : in compound_name_nonterminal2) return Parseable_Token_Ptr is
   begin
      return(This.simple_name_part.Identifier_part);
   end Get_Simple_Name;
   
   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in compound_name_nonterminal2) is
   begin
      Check_For_Supported_Package(This.compound_name_part.all);
      Check_For_Supported_Package(This.simple_name_part.all);
   end Check_For_Supported_Package;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compound_name_nonterminal2) is
   Line, Column: Integer;
   begin
      Line := This.DOT_part.line;
      Column := This.DOT_part.column;
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada compound naming not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;

   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in c_name_list_nonterminal1) is
   begin
      Check_For_Supported_Package(This.compound_name_part.all);
   end Check_For_Supported_Package;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out c_name_list_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------------------------
   -- Check_For_Supported_Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in c_name_list_nonterminal2) is
   begin
      Check_For_Supported_Package(This.c_name_list_part.all);
      Check_For_Supported_Package(This.compound_name_part.all);
   end Check_For_Supported_Package;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out c_name_list_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out used_char_nonterminal) is
   begin
      Translate(This.char_lit_part.all);
   end Translate;

   ------------
   -- Get_LC --
   ------------
   procedure Get_LC (This : in operator_symbol_nonterminal; Line, Column : out integer) is
   begin
      Get_LC(This.char_string_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out operator_symbol_nonterminal) is
   begin
      Translate(This.char_string_part.all);
   end Translate;

   ----------------------------------------
   -- Is_Supported_Predefined_Array_Type --
   ----------------------------------------
   function Is_Supported_Predefined_Array_Type (This : in indexed_comp_nonterminal) return boolean is
   begin
      return Is_Supported_Predefined_Array_Type(This.name_part.all);
   end Is_Supported_Predefined_Array_Type;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in indexed_comp_nonterminal) return integer is
   begin
      return Get_Arity(This.value_s_part.all);
   end Get_Arity;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in indexed_comp_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.value_s_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in indexed_comp_nonterminal) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.value_s_part.all);
   end Get_Upper_Bound;
   
      
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out indexed_comp_nonterminal; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.value_s_part.all, From => From, To => To);
   end Change_Identifiers;
   
   --------------------------
   -- Check_For_Array_Refs --
   --------------------------
   procedure Check_For_Array_Refs(This : in indexed_comp_nonterminal) is
   Val : Value_nonterminal_ptr;
   Arity : Integer := Get_Arity(This);
   Line, Column : Integer;
   begin
      for i in 1..Arity loop
         Val := Find_Nth_Argument(This.value_s_part.all, i, Arity);
         if Contains_Array_Ref(Get_Expression(Val.all).all) then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, Item => " Array elements can't be parameters in Ada/Mindstorms."); 
            new_line(File => Standard_Error);
            put(File => Standard_Error, Item => " Try replacing the parameter with a variable.");
            raise Parse_Error_Exception;
         end if;
      end loop;
   end Check_For_Array_Refs;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in indexed_comp_nonterminal; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------------------------
   -- Put_Args_In_Right_Positions --
   ---------------------------------
   procedure Put_Args_In_Right_Positions(This : in out indexed_comp_nonterminal) is
   Val, Val_t : Value_nonterminal_ptr;
   Chase : Value_s_nonterminal_ptr;
   Arity : Integer := Get_Arity(This);
   As_Called, As_Declared : Unbounded_String;
   found : Boolean := false;
   Line, Column : Integer;
   begin
      for i in 1..Arity loop
         Val := Find_Nth_Argument(This.value_s_part.all, i, Arity);
         
         if Is_Named_Association(Val.all) then
            As_Called := To_Unbounded_String(To_Upper(To_String(LHS_Of_Assoc(Val.all))));
            As_Declared := To_Unbounded_String(To_Upper(To_String(Name_Of_Formal_As_Declared(This => This, 
               i => i, Arity => Arity))));
            if  As_Called /= As_Declared then
               --find the correct argument in the value list
               for j in (i+1)..Arity loop
                  Val_t := Find_Nth_Argument(This.value_s_part.all, j, Arity);
                  As_Called := To_Unbounded_String(To_Upper(To_String(LHS_Of_Assoc(Val_t.all))));
                  --when found, swap it with the one in the current (incorrect) position
                  if As_Called = As_Declared then
                     --set ith value to val_t (the correct one)
                     Chase := This.value_s_part;
                     for k in 1..(Arity-i) loop
                        Chase := Get_Value_S_Part(Chase.all);
                     end loop;
                     Set_Value_Part(Chase.all,Val_t);
                     --set jth value to val (the incorrect one, will be fixed in succeeding iterations)
                     Chase := This.value_s_part;
                     for k in 1..(Arity-j) loop
                        Chase := Get_Value_S_Part(Chase.all);
                     end loop;
                     Set_Value_Part(Chase.all,Val);
                     found := true; 
                     exit;   
                  end if;
               end loop;
                 
               --should always find the indicated function/proc, something is wrong
               if not found then
                  Get_LC(This, Line, Column);
                  Error_Msg_Prefix(Line, Column);
                  put(File => Standard_Error, Item => " no match for formal parameter ");                   
                  put(File => Standard_Error, Item => To_String(As_Declared));
                  new_line(File => Standard_Error);
                  put(File => Standard_Error, Item => "Did you forget to run your program through AdaGide?");
                  new_line(File => Standard_Error);
                  raise Parse_Error_Exception;
               end if;
            end if;
         end if;
      end loop;
   end Put_Args_In_Right_Positions;
   
   ---------------------------
   -- Check_NQC_Constraints --
   ---------------------------
   --enforce what NQC API constraints we choose to here (constant arguments, global vars only, etc)
   --assumes code has already been translated, arguments now in right order
   procedure Check_NQC_Constraints(This : in indexed_comp_nonterminal) is
   Name_String : String := To_Upper(To_String(LHS_Of_Assoc(This.name_part.all)));
   Id : Parseable_Token_Ptr;
   Id_String : Unbounded_String;
   Val : Value_Nonterminal_Ptr;
   Expr : Expression_Nonterminal_Ptr;
   Good : boolean;
   Line, Column : integer;
   Arity : integer := Get_Arity(This);
   begin
      --Clear_Sensor must have constant argument
      if Name_String = "CLEAR_SENSOR" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Clear_Sensor must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Clear_Timer must have constant argument
      elsif Name_String = "CLEAR_TIMER" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Clear_Timer must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Create_Datalog must have constant argument
      elsif Name_String = "CREATE_DATALOG" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Create_Datalog must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Config_Sensor must have constant for "Sensor" parameter
      elsif Name_String = "CONFIG_SENSOR" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Sensor' argument to Config_Sensor must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Display_Value must have a global variable for "Value" parameter, constant for "Decimal_Places"
      elsif Name_String = "DISPLAY_VALUE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         if Is_Identifier(Expr.all) then
            Id := Get_Identifier(Expr.all);
            Id_String := To_Unbounded_String(Id.Token_String.all);
            if Proc_Nesting_Level = 1 then
               Good := Is_Global_Variable(Id_String);
            else   --Proc_Nesting_Level = 2, must make sure no identifier with same name in local scope
               Good := (not Is_Local_Variable(Id_String)) and Is_Global_Variable(Id_String);
            end if;
            if not Good then
               Line := Id.Line;
               Column := Id.Column;
               Error_Msg_Prefix(Line, Column);
               put(file => standard_error, item => "'Value' argument to Display_Value must be declared in the main procedure");
               new_line(file => standard_error);
               put(file => standard_error, item => "or be a global variable. Try rewriting your code so that what you need to");
               new_line(file => standard_error);
               put(file => standard_error, item => "see is in the main procedure and recompile.");
               raise Parse_Error_Exception;
            end if;
         end if;
         --now check 2nd argument (Decimal_Places)
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Decimal_Places' argument to Display_Value must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Boolean_Sensor_Value must have constant argument
      elsif Name_String = "GET_BOOLEAN_SENSOR_VALUE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Boolean_Sensor_Value must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Global_Output_Mode must have constant argument
      elsif Name_String = "GET_GLOBAL_OUTPUT_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Global_Output_Mode must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Output_Mode must have constant argument
      elsif Name_String = "GET_OUTPUT_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Output_Mode must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Raw_Sensor_Value must have constant argument
      elsif Name_String = "GET_RAW_SENSOR_VALUE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Raw_Sensor_Value must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Sensor_Mode must have constant argument
      elsif Name_String = "GET_SENSOR_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Sensor_Mode must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Sensor_Type must have constant argument
      elsif Name_String = "GET_SENSOR_TYPE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Sensor_Type must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Get_Timer must have constant argument
      elsif Name_String = "GET_TIMER" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Get_Timer must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Float must have constant argument
      elsif Name_String = "OUTPUT_FLOAT" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_Float must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Forward must have constant argument
      elsif Name_String = "OUTPUT_FORWARD" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_Forward must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Off must have constant argument
      elsif Name_String = "OUTPUT_OFF" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_Off must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_On must have constant argument
      elsif Name_String = "OUTPUT_ON" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_On must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_On_For must have constant for "Output" parameter
      elsif Name_String = "OUTPUT_ON_FOR" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Output' argument to Output_On_For must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_On_Forward must have constant argument
      elsif Name_String = "OUTPUT_ON_FORWARD" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_On_Forward must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_On_Reverse must have constant argument
      elsif Name_String = "OUTPUT_ON_REVERSE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_On_Reverse must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Power must have constant for "Output" parameter
      elsif Name_String = "OUTPUT_POWER" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Output' argument to Output_Power must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Reverse must have constant argument
      elsif Name_String = "OUTPUT_FORWARD" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_Reverse must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Output_Toggle must have constant argument
      elsif Name_String = "OUTPUT_TOGGLE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Output_Toggle must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Play_Sound must have constant argument
      elsif Name_String = "PLAY_SOUND" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Play_Sound must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Play_Tone must have constant Tenths_Of_A_Second argument
      elsif Name_String = "PLAY_TONE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Tenths_Of_A_Second' argument to Play_Tone must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Random must have constant argument
      elsif Name_String = "RANDOM" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Random must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Global_Output_Direction must have both arguments constant
      elsif Name_String = "SET_GLOBAL_OUTPUT_DIRECTION" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Global_Output_Direction must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Global_Output_Mode must have both arguments constant
      elsif Name_String = "SET_GLOBAL_OUTPUT_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Global_Output_Mode must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Max_Power must have constant for "Output" parameter
      elsif Name_String = "SET_MAX_POWER" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "'Output' argument to Set_Max_Power must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Output_Direction must have both arguments constant
      elsif Name_String = "SET_OUTPUT_DIRECTION" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Output_Direction must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Output_Mode must have both arguments constant
      elsif Name_String = "SET_OUTPUT_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Output_Mode must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Sensor_Mode must have both arguments constant
      elsif Name_String = "SET_SENSOR_MODE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Sensor_Mode must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Sensor_Type must have both arguments constant
      elsif Name_String = "SET_SENSOR_TYPE" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Sensor_Type must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Transmitter_Power_Level must have constant argument
      elsif Name_String = "SET_TRANSMITTER_POWER_LEVEL" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "argument to Set_Transmitter_Power_Level must be a constant.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      --Set_Watch must have both arguments constant
      elsif Name_String = "SET_WATCH" then
         Val := Find_Nth_Argument(This.value_s_part.all, 1, Arity);
         Expr := Get_Expression(Val.all);
         Good := Is_Constant(Expr.all);
         Val := Find_Nth_Argument(This.value_s_part.all, 2, Arity);
         Expr := Get_Expression(Val.all);
         Good := Good and then Is_Constant(Expr.all);
         if not Good then
            Get_LC(This, Line, Column);
            Error_Msg_Prefix(Line, Column);
            put(file => standard_error, item => "Both arguments to Set_Watch must be constants.");
            new_line(file => standard_error);
            raise Parse_Error_Exception;
         end if;
      end if;
   end Check_NQC_Constraints;
   
   ---------------
   -- Translate --
   ---------------
   --procedure call, function call, or array reference:  name '(' values ')'
   procedure Translate (This : in out indexed_comp_nonterminal) is
   Arity : Integer := Get_Arity(This);
   Info_Rec : Lego_Builtins.Procedure_Info_Record_Type;
   User_Type : object_subtype_def_nonterminal_ptr;
   Lower_Bound : simple_expression_nonterminal_ptr;
   Is_Procedure_Or_Function : boolean;
   Name_String : String := To_Upper(To_String(LHS_Of_Assoc(This.name_part.all)));
   Ignored_L, Ignored_C : integer := 0;   --suppress compiler warning
   begin
      Get_Proc_Info(This => Name_String, 
         Arity => Arity, Line => Ignored_L, Column => Ignored_C, Found => Is_Procedure_Or_Function, Info => Info_Rec);
      if Is_Procedure_Or_Function then   --function/procedure call?
         Check_For_Array_Refs(This);   --no array references allowed as parameters
         if Arity > 1 then
            Put_Args_In_Right_Positions(This);   
         end if;
         --translate to ensure valid syntax, makes NQC constraint checks easier
         Translate(This.name_part.all);
         Translate(This.L_PAREN_part.all);
         Translate(This.value_s_part.all);
         Translate(This.R_PAREN_part.all);
         if Is_Ada_Mindstorms_Procedure(Name_String) then
            Check_NQC_Constraints(This);   --NQC API calls have some rather arbitrary constraints, check them here
         end if;
         
      else   --array reference
         --in future releases, might want to add a check for an undefined array variable here
         Translate(This.name_part.all);
         put("[");
         Translate(This.L_PAREN_part.all);
         Translate(This.value_s_part.all);
         Translate(This.R_PAREN_part.all);
         put("-");
         put("(");
         User_Type := Get_Object_Subtype_Def(This.name_part.all);
         Lower_Bound := Get_Lower_Bound(User_Type.all);
         Translate(Lower_Bound.all);
         put(")");
         put("]");
      end if;
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in value_s_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.value_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in value_s_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.value_part.all);
   end Get_Upper_Bound;
   
   -----------------------
   -- Find Nth Argument --
   -----------------------
   function Find_Nth_Argument(This : in value_s_nonterminal1; Target, Arity : in integer)
      return value_nonterminal_ptr is
   begin
      return Find_Nth_Argument_From_Right(This, Arity-Target+1, 1);
   end Find_Nth_Argument;
   
   ----------------------------------
   -- Find Nth Argument_From_Right --
   ----------------------------------
   --defined this way because of left-recursive definition of the nonterminal
   function Find_Nth_Argument_From_Right(This : in value_s_nonterminal1; Target, Current : in integer)
      return value_nonterminal_ptr is
   begin
      return This.value_part;
   end Find_Nth_Argument_From_Right;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in value_s_nonterminal1) return integer is
   begin
      return 1;
   end Get_Arity;
   
   ----------------------
   -- Get_Value_S_Part --
   ----------------------
   -- should never be called
   function Get_Value_S_Part(This : in value_s_nonterminal1) return value_s_nonterminal_ptr is
   begin
      return null;
   end Get_Value_S_Part;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_s_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.value_part.all, From => From, To => To);
   end Change_Identifiers;
   
   --------------------
   -- Set_Value_Part --
   --------------------
   procedure Set_Value_Part(This : in out value_s_nonterminal1; Val : in value_nonterminal_ptr) is
   begin
      This.value_part := Val;
   end;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_s_nonterminal1) is
   begin
      Translate(This.value_part.all);
   end Translate;
   
   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound(This : in value_s_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound(This : in value_s_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   -----------------------
   -- Find Nth Argument --
   -----------------------
   function Find_Nth_Argument(This : in value_s_nonterminal2; Target, Arity : in integer)
      return value_nonterminal_ptr is
   begin
      return Find_Nth_Argument_From_Right(This, Arity-Target+1, 1);
   end Find_Nth_Argument;
   
   ----------------------------------
   -- Find Nth Argument_From_Right --
   ----------------------------------
   --defined this way because of left-recursive definition of the nonterminal
   function Find_Nth_Argument_From_Right(This : in value_s_nonterminal2; Target, Current : in integer)
      return value_nonterminal_ptr is
   begin
      if Target = Current then
         return This.value_part;
      else
         return Find_Nth_Argument_From_Right(This.value_s_part.all, Target, Current+1);
      end if;
   end Find_Nth_Argument_From_Right;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in value_s_nonterminal2) return integer is
   begin
      return Get_Arity(This.value_s_part.all) + 1;
   end Get_Arity;
   
   ----------------------
   -- Get_Value_S_Part --
   ----------------------
   function Get_Value_S_Part(This : in value_s_nonterminal2) return value_s_nonterminal_ptr is
   begin
      return This.value_s_part;
   end Get_Value_S_Part;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_s_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.value_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.value_part.all, From => From, To => To);
   end Change_Identifiers;
   
   --------------------
   -- Set_Value_Part --
   --------------------
   procedure Set_Value_Part(This : in out value_s_nonterminal2; Val : in value_nonterminal_ptr) is
   begin
      This.value_part := Val;
   end;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_s_nonterminal2) is
   begin
      Translate(This.value_s_part.all);
      Translate(This.COMMA_part.all);
      Translate(This.value_part.all);
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound (This : in value_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound (This : in value_nonterminal1) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   --------------------
   -- Get_Expression --
   --------------------
   function Get_Expression(This : in value_nonterminal1) return expression_nonterminal_ptr is
   begin
      return This.expression_part;
   end Get_Expression;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc(This : in value_nonterminal1) return Unbounded_String is
   begin
      return(To_Unbounded_String(""));
   end LHS_Of_Assoc;
   
   --------------------------
   -- Is_Named_Association --
   --------------------------
   function Is_Named_Association(This : in value_nonterminal1) return boolean is
   begin
      return false;
   end Is_Named_Association;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_nonterminal1) is
   begin
      Translate(This.expression_part.all); 
   end Translate;

---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound (This : in value_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound (This : in value_nonterminal2) return simple_expression_nonterminal_ptr is
   begin
      return null;
   end Get_Upper_Bound;
   
   --------------------
   -- Get_Expression --
   --------------------
   function Get_Expression(This : in value_nonterminal2) return expression_nonterminal_ptr is
   begin
      return Get_Expression(This.comp_assoc_part.all);
   end Get_Expression;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This : in value_nonterminal2) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.comp_assoc_part.all);
   end LHS_Of_Assoc;
   
   --------------------------
   -- Is_Named_Association --
   --------------------------
   function Is_Named_Association(This : in value_nonterminal2) return boolean is
   begin
      return true;
   end Is_Named_Association;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.comp_assoc_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_nonterminal2) is
   begin
      Translate(This.comp_assoc_part.all);
   end Translate;

   ---------------------
   -- Get_Lower_Bound --
   ---------------------
   function Get_Lower_Bound (This : in value_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return Get_Lower_Bound(This.discrete_with_range_part.all);
   end Get_Lower_Bound;
   
   ---------------------
   -- Get_Upper_Bound --
   ---------------------
   function Get_Upper_Bound (This : in value_nonterminal3) return simple_expression_nonterminal_ptr is
   begin
      return Get_Upper_Bound(This.discrete_with_range_part.all);
   end Get_Upper_Bound;
   
   --------------------
   -- Get_Expression --
   --------------------
   --should never be called
   function Get_Expression(This : in value_nonterminal3) return expression_nonterminal_ptr is
   begin
      return null;
   end Get_Expression;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc(This : in value_nonterminal3) return Unbounded_String is
   begin
      return(To_Unbounded_String(""));
   end LHS_Of_Assoc;
   
   --------------------------
   -- Is_Named_Association --
   --------------------------
   function Is_Named_Association(This : in value_nonterminal3) return boolean is
   begin
      return false;
   end Is_Named_Association;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.discrete_with_range_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_nonterminal3) is
   begin
      Translate(This.discrete_with_range_part.all);
   end Translate;

   ---------------------------------
   -- Check For Supported Package --
   ---------------------------------
   procedure Check_For_Supported_Package(This : in selected_comp_nonterminal1) is
   Line : Integer := This.simple_name_part.IDENTIFIER_part.Line;
   Column : Integer := This.simple_name_part.IDENTIFIER_part.Column;
   --Currently, Ada/Mindstorms doesn't support compound packages      
   --Would be nice at some point to reconstruct the actual offending package name
   begin
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " This package is not supported by Ada/Mindstorms.");
      new_line(File => Standard_Error);
      put(File => Standard_Error, Item => "Currently, only the package 'lego' can be used here.");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in selected_comp_nonterminal1; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out selected_comp_nonterminal1) is
   begin
      Translate(This.name_part.all);
      Translate(This.DOT_part.all);
      --more tree here
   end Translate;

   ---------------------------------
   -- Check For Supported Package --
   ---------------------------------
   -- should never be called
   procedure Check_For_Supported_Package(This : in selected_comp_nonterminal2) is
   begin
     null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in selected_comp_nonterminal2; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out selected_comp_nonterminal2) is
   begin
      Translate(This.name_part.all);
      Translate(This.DOT_part.all);
      --more tree here
   end Translate;

   ---------------------------------
   -- Check For Supported Package --
   ---------------------------------
   -- should never be called
   procedure Check_For_Supported_Package(This : in selected_comp_nonterminal3) is
   begin
     null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in selected_comp_nonterminal3; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out selected_comp_nonterminal3) is
   begin
      Translate(This.name_part.all);
      Translate(This.DOT_part.all);
      --more tree here
   end Translate;

   ---------------------------------
   -- Check For Supported Package --
   ---------------------------------
   -- should never be called
   procedure Check_For_Supported_Package(This : in selected_comp_nonterminal4) is
   begin
     null;
   end Check_For_Supported_Package;
   
   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in selected_comp_nonterminal4; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out selected_comp_nonterminal4) is
   begin
      Translate(This.name_part.all);
      Translate(This.DOT_part.all);
      --more tree here
   end Translate;

   ------------
   -- Get_LC --
   ------------
   procedure Get_LC(This : in attribute_nonterminal; Line, Column : out integer) is
   begin
      Get_LC(This.name_part.all, Line, Column);
   end Get_LC;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attribute_nonterminal) is
   begin
      Translate(This.name_part.all);
      Translate(This.TICK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attribute_id_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attribute_id_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attribute_id_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attribute_id_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out literal_nonterminal1) is
   begin
      Translate(This.numeric_lit_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out literal_nonterminal2) is
   begin
      Translate(This.used_char_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out literal_nonterminal3) is
   begin
      Translate(This.NULL_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out aggregate_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.comp_assoc_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aggregate_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out aggregate_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.value_s_2_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aggregate_nonterminal2) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   -- L_PAREN expression WITH value_s R_PAREN, not supported
   procedure Change_Identifiers(This : in out aggregate_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aggregate_nonterminal3) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   -- L_PAREN expression WITH NULL RECORD R_PAREN, not supported
   procedure Change_Identifiers(This : in out aggregate_nonterminal4; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aggregate_nonterminal4) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   -- L_PAREN NULL RECORD R_PAREN, not supported
   procedure Change_Identifiers(This : in out aggregate_nonterminal5; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out aggregate_nonterminal5) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_s_2_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_s_2_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out value_s_2_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out value_s_2_nonterminal2) is
   begin
      null;
   end Translate;

   --------------------
   -- Get_Expression --
   --------------------
   function Get_Expression(This : in comp_assoc_nonterminal) return expression_nonterminal_ptr is
   begin
      return This.expression_part;
   end Get_Expression;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This : in comp_assoc_nonterminal) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.choice_s_part.all);
   end LHS_Of_Assoc;
   
   -----------------------
   -- Change_Identifier --
   -----------------------
   procedure Change_Identifiers(This : in out comp_assoc_nonterminal; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.choice_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   --formal => actual
   procedure Translate (This : in out comp_assoc_nonterminal) is
   begin
   --ignore the left hand argument and the arrow, previous code
   --should have fixed the tree for named association
      Translate(This.expression_part.all);
   end Translate;
   
   ------------------------
   -- Contains_Array_Ref --
   ------------------------
   function Contains_Array_Ref(This : in expression_nonterminal1) return boolean is
   begin
      return false;   --BSF
   end Contains_Array_Ref;
   
   ----------------------------
   -- Is_Constant_Expression --
   ----------------------------
   function Is_Constant(This : in expression_nonterminal1) return boolean is
   begin
      return Is_Constant(This.relation_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in expression_nonterminal1) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.relation_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in expression_nonterminal1) return boolean is
   begin
      return Is_Identifier(This.relation_part.all);
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This : in expression_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.relation_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  expression_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.relation_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out expression_nonterminal1) is
   begin
      Translate(This.relation_part.all);
   end Translate;

   ------------------------
   -- Contains_Array_Ref --
   ------------------------
   function Contains_Array_Ref(This : in expression_nonterminal2) return boolean is
   begin
      return false;   --BSF
   end Contains_Array_Ref;
   
   ----------------------------
   -- Is_Constant_Expression --
   ----------------------------
   function Is_Constant(This : in expression_nonterminal2) return boolean is
   begin
      return Is_Constant(This.expression_part.all) and Is_Constant(This.relation_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in expression_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in expression_nonterminal2) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc(This : in expression_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  expression_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
      Change_Identifiers(This => This.relation_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out expression_nonterminal2) is
   begin
      put_with_space("(");
      Translate(This.expression_part.all);
      put_with_space(")");
      Translate(This.logical_part.all);
      put_with_space("(");
      Translate(This.relation_part.all);
      put_with_space(")");
   end Translate;

   ------------------------
   -- Contains_Array_Ref --
   ------------------------
   function Contains_Array_Ref(This : in expression_nonterminal3) return boolean is
   begin
      return false;   --BSF
   end Contains_Array_Ref;
   
   ----------------------------
   -- Is_Constant_Expression --
   ----------------------------
   function Is_Constant(This : in expression_nonterminal3) return boolean is
   begin
      return Is_Constant(This.expression_part.all) and Is_Constant(This.relation_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in expression_nonterminal3) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in expression_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   --should never be called
   function LHS_Of_Assoc(This : in expression_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  expression_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
      Change_Identifiers(This => This.relation_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out expression_nonterminal3) is
   begin
      Translate(This.expression_part.all);
      Translate(This.short_circuit_part.all);
      Translate(This.relation_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out logical_nonterminal1) is
   begin
      Translate(This.AND_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out logical_nonterminal2) is
   begin
      Translate(This.OR_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out logical_nonterminal3) is
   begin
      Translate(This.XOR_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out short_circuit_nonterminal1) is
   Line : Integer := This.AND_part.Line;
   Column : Integer := This.AND_part.Column;
   begin
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada short circuits not supported.");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out short_circuit_nonterminal2) is
   Line : Integer := This.OR_part.Line;
   Column : Integer := This.OR_part.Column;
   begin
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada short circuits not supported.");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in relation_nonterminal1) return boolean is
   begin
      return Is_Constant(This.simple_expression_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in relation_nonterminal1) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.simple_expression_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in relation_nonterminal1) return boolean is
   begin
      return Is_Identifier(This.simple_expression_part.all);
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This: in relation_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.simple_expression_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out relation_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relation_nonterminal1) is
   begin
      Translate(This.simple_expression_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in relation_nonterminal2) return boolean is
   begin
      return Is_Constant(This.simple_expression_part1.all) and Is_Constant(This.simple_expression_part2.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in relation_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in relation_nonterminal2) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   -- should never be called --
   function LHS_Of_Assoc(This: in relation_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out relation_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_expression_part1.all, From => From, To => To);
      Change_Identifiers(This => This.simple_expression_part2.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relation_nonterminal2) is
   begin
      Translate(This.simple_expression_part1.all);
      Translate(This.relational_part.all);
      Translate(This.simple_expression_part2.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in relation_nonterminal3) return boolean is
   begin
      return Is_Constant(This.simple_expression_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in relation_nonterminal3) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.simple_expression_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in relation_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   -- should never be called --
   function LHS_Of_Assoc(This: in relation_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out relation_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_expression_part.all, From => From, To => To);
      Change_Identifiers(This => This.range_sym_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relation_nonterminal3) is
   begin
      Translate(This.simple_expression_part.all);
      Translate(This.membership_part.all);
      Translate(This.range_sym_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in relation_nonterminal4) return boolean is
   begin
      return Is_Constant(This.simple_expression_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in relation_nonterminal4) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in relation_nonterminal4) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   -- should never be called --
   function LHS_Of_Assoc(This: in relation_nonterminal4) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out relation_nonterminal4; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_expression_part.all, From => From, To => To);
      Change_Identifiers(This => This.name_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relation_nonterminal4) is
   begin
      Translate(This.simple_expression_part.all);
      Translate(This.membership_part.all);
      Translate(This.name_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal1) is
   begin
      Translate(This.EQ_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal2) is
   begin
      Translate(This.NE_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal3) is
   begin
      Translate(This.LT_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal4) is
   begin
      Translate(This.LT_EQ_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal5) is
   begin
      Translate(This.GT_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out relational_nonterminal6) is
   begin
      Translate(This.GE_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out membership_nonterminal1) is
   begin
      Translate(This.IN_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out membership_nonterminal2) is
   begin
      Translate(This.NOT_part.all);
      Translate(This.IN_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in simple_expression_nonterminal1) return boolean is
   begin
      return Is_Constant(This.term_part.all);
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in simple_expression_nonterminal1) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in simple_expression_nonterminal1) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   -- should never be called
   function LHS_Of_Assoc(This : in simple_expression_nonterminal1) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out simple_expression_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.term_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_expression_nonterminal1) is
   begin
      Translate(This.unary_part.all);
      Translate(This.term_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in simple_expression_nonterminal2) return boolean is
   begin
      return Is_Constant(This.term_part.all);
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in simple_expression_nonterminal2) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.term_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in simple_expression_nonterminal2) return boolean is
   begin
      return Is_Identifier(This.term_part.all);
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   function LHS_Of_Assoc(This : in simple_expression_nonterminal2) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.term_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out simple_expression_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.term_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_expression_nonterminal2) is
   begin
      Translate(This.term_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in simple_expression_nonterminal3) return boolean is
   begin
      return Is_Constant(This.simple_expression_part.all) and Is_Constant(This.term_part.all);
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in simple_expression_nonterminal3) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in simple_expression_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in simple_expression_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out simple_expression_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.simple_expression_part.all, From => From, To => To);
      Change_Identifiers(This => This.term_part.all, From => From, To => To);
   end Change_Identifiers;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_expression_nonterminal3) is
   begin
      Translate(This.simple_expression_part.all);
      Translate(This.adding_part.all);
      Translate(This.term_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unary_nonterminal1) is
   Line : Integer := This.PLUS_part.line;
   Column : Integer := This.PLUS_part.column;
   begin
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => ", unary plus not supported.");
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unary_nonterminal2) is
   begin
      Translate(This.MINUS_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out adding_nonterminal1) is
   begin
      Translate(This.PLUS_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out adding_nonterminal2) is
   begin
      Translate(This.MINUS_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out adding_nonterminal3) is
   begin
      Translate(This.CONCAT_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in term_nonterminal1) return boolean is
   begin
      return Is_Constant(This.factor_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in term_nonterminal1) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.factor_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in term_nonterminal1) return boolean is
   begin
      return Is_Identifier(This.factor_part.all);
   end Is_Identifier;
   
   -----------------------------
   -- LHS_Of_Assoc --
   ------------------------------
   function LHS_Of_Assoc(This : in term_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.factor_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out term_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.factor_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out term_nonterminal1) is
   begin
      Translate(This.factor_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in term_nonterminal2) return boolean is
   begin
      return Is_Constant(This.term_part.all) and Is_Constant(This.factor_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in term_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in term_nonterminal2) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc(This : in term_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out term_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.term_part.all, From => From, To => To);
      Change_Identifiers(This => This.factor_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out term_nonterminal2) is
   begin
      Translate(This.term_part.all);
      Translate(This.multiplying_part.all);
      Translate(This.factor_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out multiplying_nonterminal1) is
   begin
      Translate(This.STAR_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out multiplying_nonterminal2) is
   begin
      Translate(This.SLASH_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out multiplying_nonterminal3) is
   begin
      Translate(This.MOD_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out multiplying_nonterminal4) is
   begin
      Translate(This.REM_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in factor_nonterminal1) return boolean is
   begin
      return Is_Constant(This.primary_part.all);
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in factor_nonterminal1) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.primary_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in factor_nonterminal1) return boolean is
   begin
      return Is_Identifier(This.primary_part.all);
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   function LHS_Of_Assoc (This : in factor_nonterminal1) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.primary_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out factor_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.primary_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out factor_nonterminal1) is
   begin
      Translate(This.primary_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in factor_nonterminal2) return boolean is
   begin
      return Is_Constant(This.primary_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in factor_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in factor_nonterminal2) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc (This : in factor_nonterminal2) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out factor_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.primary_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out factor_nonterminal2) is
   begin
      Translate(This.NOT_part.all);
      Translate(This.primary_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in factor_nonterminal3) return boolean is
   begin
      return Is_Constant(This.primary_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in factor_nonterminal3) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in factor_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc (This : in factor_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out factor_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.primary_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out factor_nonterminal3) is
   begin
      Translate(This.ABS_part.all);   --ABS in Ada becomes a function call in NQC
      put("(");
      Translate(This.primary_part.all);
      put(")");
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in factor_nonterminal4) return boolean is
   begin
      return Is_Constant(This.primary_part1.all) and Is_Constant(This.primary_part2.all);
   end Is_Constant;
   
   --------------------
   -- Get_Identifier --
   --------------------
   function Get_Identifier(This : in factor_nonterminal4) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : in factor_nonterminal4) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called
   function LHS_Of_Assoc (This : in factor_nonterminal4) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out factor_nonterminal4; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.primary_part1.all, From => From, To => To);
      Change_Identifiers(This => This.primary_part2.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out factor_nonterminal4) is
   begin
      Translate(This.primary_part1.all);
      Translate(This.EXPONENT_part.all);
      Translate(This.primary_part2.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   --literal
   function Is_Constant(This : in primary_nonterminal1) return boolean is
   begin
      return true;
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in primary_nonterminal1) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : primary_nonterminal1) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called --
   function LHS_Of_Assoc (This : in primary_nonterminal1) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   --literal, has no identifiers to change
   procedure Change_Identifiers(This : in out primary_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out primary_nonterminal1) is
   begin
      Translate(This.literal_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in primary_nonterminal2) return boolean is
   begin
      return Is_Constant(This.name_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in primary_nonterminal2) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.name_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : primary_nonterminal2) return boolean is
   begin
      return Is_Identifier(This.name_part.all);
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   function LHS_Of_Assoc (This : in primary_nonterminal2) return Unbounded_String is
   begin
      return LHS_Of_Assoc(This.name_part.all);
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out primary_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.name_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out primary_nonterminal2) is
   begin
      Translate(This.name_part.all);
      --Ada doesn't have different syntax for integers and 0-arity functions that return
      --integers, but NQC does [foo vs foo()]
      if Get_Arity(This.name_part.all) = 0 and Is_In_Proc_Table(This => To_String(LHS_Of_Assoc(This.name_part.all)), 
      Arity => 0 ) then
         put_with_space("()"); 
      end if;
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   --allocator
   function Is_Constant(This : in primary_nonterminal3) return boolean is
   begin
      return false;
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in primary_nonterminal3) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : primary_nonterminal3) return boolean is
   begin
      return false;
   end Is_Identifier;   
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called --
   function LHS_Of_Assoc (This : in primary_nonterminal3) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   --allocator, not supported
   procedure Change_Identifiers(This : in out primary_nonterminal3; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out primary_nonterminal3) is
   begin
      Translate(This.allocator_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   --qualified
   function Is_Constant(This : in primary_nonterminal4) return boolean is
   begin
      return false;
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in primary_nonterminal4) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : primary_nonterminal4) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called --
   function LHS_Of_Assoc (This : in primary_nonterminal4) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   --qualified, not supported
   procedure Change_Identifiers(This : in out primary_nonterminal4; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out primary_nonterminal4) is
   begin
      Translate(This.qualified_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in primary_nonterminal5) return boolean is
   begin
      return Is_Constant(This.parenthesized_primary_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in primary_nonterminal5) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.parenthesized_primary_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier(This : primary_nonterminal5) return boolean is
   begin
      return Is_Identifier(This.parenthesized_primary_part.all);
   end Is_Identifier;
   
   ------------------
   -- LHS_Of_Assoc --
   ------------------
   -- should never be called --
   function LHS_Of_Assoc (This : in primary_nonterminal5) return Unbounded_String is
   begin
      return To_Unbounded_String("");
   end LHS_Of_Assoc;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out primary_nonterminal5; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.parenthesized_primary_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out primary_nonterminal5) is
   begin
      Translate(This.parenthesized_primary_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in parenthesized_primary_nonterminal1) return boolean is
   begin
      return false;
   end Is_Constant;

   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in parenthesized_primary_nonterminal1) return Parseable_Token_Ptr is
   begin
      return null;
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in parenthesized_primary_nonterminal1) return boolean is
   begin
      return false;
   end Is_Identifier;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out parenthesized_primary_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.aggregate_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out parenthesized_primary_nonterminal1) is
   begin
      Translate(This.aggregate_part.all);
   end Translate;

   -----------------
   -- Is_Constant --
   -----------------
   function Is_Constant(This : in parenthesized_primary_nonterminal2) return boolean is
   begin
      return Is_Constant(This.expression_part.all);
   end Is_Constant;
   
   -------------------------
   -- Get_Identifier --
   -------------------------
   function Get_Identifier(This : in parenthesized_primary_nonterminal2) return Parseable_Token_Ptr is
   begin
      return Get_Identifier(This.expression_part.all);
   end Get_Identifier;
   
   -------------------
   -- Is_Identifier --
   -------------------
   function Is_Identifier (This : in parenthesized_primary_nonterminal2) return boolean is
   begin
      return Is_Identifier(This.expression_part.all);
   end Is_Identifier;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out parenthesized_primary_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out parenthesized_primary_nonterminal2) is
   begin
      Translate(This.L_PAREN_part.all);
      Translate(This.expression_part.all);
      Translate(This.R_PAREN_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out qualified_nonterminal) is
   begin
      Translate(This.name_part.all);
      Translate(This.TICK_part.all);
      Translate(This.parenthesized_primary_part.all);
      
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out allocator_nonterminal1) is
   begin
      Translate(This.NEW_part.all);
      Translate(This.name_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out allocator_nonterminal2) is
   begin
      Translate(This.NEW_part.all);
      Translate(This.qualified_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  statement_s_nonterminal1;
      From : in Parseable_Token_Ptr; To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.statement_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in statement_s_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_part.all, Decls);
   end Mark_For_Loops;
                        
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out statement_s_nonterminal1) is
   begin
      Translate(This.statement_part.all);
      my_new_line;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  statement_s_nonterminal2;
      From : in Parseable_Token_Ptr; To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.statement_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.statement_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in statement_s_nonterminal2;
   Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
      Mark_For_Loops(This.statement_part.all, Decls);
   end Mark_For_Loops;
         
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out statement_s_nonterminal2) is
   begin
      Translate(This.statement_s_part.all);
      Translate(This.statement_part.all);
   end Translate;
            
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out statement_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.unlabeled_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in statement_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.unlabeled_part.all, Decls);
   end Mark_For_Loops;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out statement_nonterminal1) is
   begin
      Translate(This.unlabeled_part.all);
   end Translate;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out statement_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.statement_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in statement_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out statement_nonterminal2) is
   begin
      Translate(This.label_part.all);
      Translate(This.statement_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out unlabeled_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.simple_stmt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in unlabeled_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.simple_stmt_part.all, Decls);
   end Mark_For_Loops;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unlabeled_nonterminal1) is
   begin
      Translate(This.simple_stmt_part.all);
   end Translate;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in unlabeled_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.compound_stmt_part.all, Decls);
   end Mark_For_Loops;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out unlabeled_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.compound_stmt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unlabeled_nonterminal2) is
   begin
      Translate(This.compound_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out unlabeled_nonterminal3;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;   --pragma_sym
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in unlabeled_nonterminal3;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;
      
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unlabeled_nonterminal3) is
   begin
      Translate(This.pragma_sym_part.all);
   end Translate;

   
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   --no need to use dispatching, no simple statements can be for loops
   procedure Mark_For_Loops (This : in simple_stmt_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      null; 
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal1) is
   begin
      Translate(This.null_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.assign_stmt_part.all, From => From, To => To);
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal2) is
   begin
      Translate(This.assign_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal3;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.exit_stmt_part.all, From => From, To => To);
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal3) is
   begin
      Translate(This.exit_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal4;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.return_stmt_part.all, From => From, To => To);
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal4) is
   begin
      Translate(This.return_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal5;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;   --goto_stmt, nothing to do
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal5) is
   begin
      Translate(This.goto_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal6;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.procedure_call_part.all, From => From, To => To);
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal6) is
   begin
      Translate(This.procedure_call_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal7;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal7) is
   begin
      Translate(This.delay_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal8;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal8) is
   begin
      Translate(This.abort_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal9;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal9) is
   begin
      Translate(This.raise_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal10;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal10) is
   begin
      Translate(This.code_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers (This : in out simple_stmt_nonterminal11;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end;   
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out simple_stmt_nonterminal11) is
   begin
      Translate(This.requeue_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal1; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.if_stmt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in compound_stmt_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.if_stmt_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   -- if cond_clause_s else_opt END IF ;
   procedure Translate (This : in out compound_stmt_nonterminal1) is
   begin
      Translate(This.if_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal2; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.case_stmt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in compound_stmt_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.case_stmt_part.all, Decls); 
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out compound_stmt_nonterminal2) is
   begin
      Translate(This.case_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal3; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.loop_stmt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in compound_stmt_nonterminal3;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.loop_stmt_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out compound_stmt_nonterminal3) is
   begin
      Translate(This.loop_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal4; From, To : in Parseable_Token_Ptr) is
   begin
      null;
      Change_Identifiers(This => This.block_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in compound_stmt_nonterminal4;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.block_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compound_stmt_nonterminal4) is
   begin
      Translate(This.block_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --accept_stmt, not supported
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal5; From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in compound_stmt_nonterminal5;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.accept_stmt_part.all, Decls);
   end Mark_For_Loops;
      
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compound_stmt_nonterminal5) is
   begin
      Translate(This.accept_stmt_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --select_stmt, not supported
   procedure Change_Identifiers(This : in out compound_stmt_nonterminal6; From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in compound_stmt_nonterminal6;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.select_stmt_part.all, Decls);
   end Mark_For_Loops;
               
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compound_stmt_nonterminal6) is
   begin
      Translate(This.select_stmt_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out label_nonterminal) is
   begin
      Translate(This.LT_LT_part.all);   --terminates translation
      Translate(This.identifier_part.all);
      Translate(This.GT_GT_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out null_stmt_nonterminal) is
   begin
      Translate(This.NULL_part.all);
      --Don't translate the semicolon, so that nulls will be ignored.
      --A single semicolon is not legal in NQC
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  assign_stmt_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.name_part.all, From => From, To => To);
      Change_Identifiers(This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out assign_stmt_nonterminal) is
   begin
      Translate(This.name_part.all);
      Translate(This.ASSIGNMENT_part.all);
      Translate(This.expression_part.all);
      Translate(This.SEMICOLON_part.all);
      my_new_line;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out if_stmt_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.cond_clause_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.else_opt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in if_stmt_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.cond_clause_s_part.all, Decls);
      Mark_For_Loops(This.else_opt_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   -- if cond_clause_s else_opt END IF ;
   procedure Translate (This : in out if_stmt_nonterminal) is
   begin
      Translate(This.IF_part1.all);
      Translate(This.cond_clause_s_part.all);
      Translate(This.else_opt_part.all);
      --ignore END IF ;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out cond_clause_s_nonterminal1; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.cond_clause_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in cond_clause_s_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.cond_clause_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out cond_clause_s_nonterminal1) is
   begin
      Translate(This.cond_clause_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out cond_clause_s_nonterminal2; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.cond_clause_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.cond_clause_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in cond_clause_s_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.cond_clause_s_part.all, Decls);
      Mark_For_Loops(This.cond_clause_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out cond_clause_s_nonterminal2) is
   begin
      Translate(This.cond_clause_s_part.all);
      Translate(This.ELSIF_part.all);   
      Translate(This.cond_clause_part.all);
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in cond_clause_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
   end Mark_For_Loops;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out cond_clause_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.cond_part_part.all, From => From, To => To);
      Change_Identifiers(This => This.statement_s_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out cond_clause_nonterminal) is
   begin
      Translate(This.cond_part_part.all);
      my_new_line;
      put("{");
      Inc_Indent;
      my_new_line;
      Translate(This.statement_s_part.all);
      Dec_Indent;
      my_new_line;
      put("}");
      my_new_line;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out cond_part_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.condition_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out cond_part_nonterminal) is
   begin
      put_with_space("(");
      Translate(This.condition_part.all);
      put_with_space(")");
      --ignore THEN keyword
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  condition_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out condition_nonterminal) is
   begin
      Translate(This.expression_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  else_opt_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in else_opt_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;
      
   ---------------
   -- Translate --
   ---------------
   --could be empty, that's fine
   procedure Translate (This : in out else_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  else_opt_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.statement_s_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in else_opt_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out else_opt_nonterminal2) is
   begin
      Translate(This.ELSE_part.all);
      my_new_line;
      put("{");
      Inc_Indent;
      my_new_line;
      Translate(This.statement_s_part.all);
      Dec_Indent;
      my_new_line;
      put("}");
      my_new_line;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  case_stmt_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.case_hdr_part.all, From => From, To => To);
      Change_Identifiers(This => This.pragma_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.alternative_s_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   
   procedure Mark_For_Loops (This : in case_stmt_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.alternative_s_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out case_stmt_nonterminal) is
   begin
      Translate(This.case_hdr_part.all);
      my_new_line;
      put_with_space("{");
      Inc_indent;
      my_new_line;
      Translate(This.alternative_s_part.all);
      Translate(This.end_part.all);   --this gives you the right brace
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  case_hdr_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   --"case expr is" becomes "switch(expr)"
   procedure Translate (This : in out case_hdr_nonterminal) is
   begin
      Translate(This.CASE_part.all);    --"case" becomes "switch" in token translation
      put_with_space("(");   --NQC requires parens around expressions for switch statements  
      Translate(This.expression_part.all);
      put_with_space(")");
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  alternative_s_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in alternative_s_nonterminal1;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   --empty alternative
   procedure Translate (This : in out alternative_s_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  alternative_s_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.alternative_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.alternative_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in alternative_s_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.alternative_s_part.all, Decls);
      Mark_For_Loops(This.alternative_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   --list of alternatives for case statement
   procedure Translate (This : in out alternative_s_nonterminal2) is
   begin
      Translate(This.alternative_s_part.all);
      Translate(This.alternative_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  alternative_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.choice_s_part.all, From => From, To => To);
      Change_Identifiers(This => This.statement_s_part.all, From => From, To => To);
   end Change_Identifiers;

   ---------------------
   -- Mark_For_Loops --
   ---------------------
   
   procedure Mark_For_Loops (This : in alternative_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------
   --alternative for case statement
   --"when expr => stmt_list" becomes "case expr: stmt_list break;"
   --"when expr0 | expr1 => stmt_list" becomes case expr0: case expr1: stmt_list break;"
   --"when others => stmt_list" becomes "default: stmt_list break;"
   procedure Translate (This : in out alternative_nonterminal) is
   begin
      Translate_For_Case_Statement(This.choice_s_part.all);
      Inc_Indent;
      my_new_line;
      Translate(This.statement_s_part.all);
      put_with_space("break;");
      Dec_Indent;
      my_new_line;
   end Translate;
  
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out  loop_stmt_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.iteration_part.all, From => From, To => To);
      Change_Identifiers(This => This.basic_loop_part.all, From => From, To => To);
   end Change_Identifiers;
   
   --------------------
   -- Mark_For_Loops --
   --------------------
   --need some access types not automatically included in trans_model.ads
   type decl_part_nonterminal2_ptr is access all decl_part_nonterminal2'Class;
   type decl_item_or_body_s1_nonterminal1_ptr is access all decl_item_or_body_s1_nonterminal1'Class;

   procedure Mark_For_Loops(This : in loop_stmt_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   Old_Range_Identifier, New_Range_Identifier : Parseable_Token_Ptr;
   Stop_Identifier : Parseable_Token_Ptr;
   Decl_Search_Result : Decl_Search_Result_Type;
   New_Decl : decl_nonterminal1_ptr;
   New_Decl_Item : decl_item_nonterminal1_ptr;
   New_Decl_Item_Or_Body : decl_item_or_body_nonterminal2_ptr;
   New_Decl_Item_Or_Body_S1 : decl_item_or_body_s1_nonterminal1_ptr;
   New_Decl_Part : decl_part_nonterminal2_ptr;
   
   begin
      if Is_For_Loop(This.Iteration_part.all) then
         --1) check identifier in iteration_part
         --2) if it's previously declared in scope, make a new unique identifier to replace it
         --3) generate another identifier by appending "_stop" to it
         --4) if that's previously declared in scope, make a unique identifier to replace it
         --5) add both identifiers to the declaration section
         --6) continue marking for loops in case of nesting
         --(see Translate procedure below for why new identifiers are necessary)
         
         Old_Range_Identifier := Get_Range_Identifier(This.iteration_part.all);
         New_Range_Identifier := Old_Range_Identifier;   --may or may not need this below, get it now just in case
         Search_And_Insert(Decls.all, Old_Range_Identifier, Decl_Search_Result);
         
         --Loop identifiers could be reused, or already declared in the declaration block.
         --Either way, the semantics are different for Ada and nqc, need to check for it.
         if Decl_Search_Result = Found_In_Decls then
            --This adds a new unique identifier to the decl block and returns it in the 2nd parameter
            Create_And_Add_Unique_Identifier(Decls.all, New_Range_Identifier);
            Set_Range_Identifier(This.iteration_part.all, New_Range_Identifier);
            --need to replace all occurences of old identifier in for loop's statement list with
            --the new identifier
            Change_Identifiers(This.basic_loop_part.all, 
               From => Old_Range_Identifier, To => New_Range_Identifier);
         elsif Decl_Search_Result = Decls_Are_Empty then   --must build a new decl section
            New_Decl := new decl_nonterminal1;
            New_Decl.object_decl_part := Make_Object_Decl(Old_Range_Identifier);
            New_Decl_Item := new decl_item_nonterminal1;
            New_Decl_Item.decl_part := decl_nonterminal_ptr(New_Decl);
            New_Decl_Item_Or_Body := new decl_item_or_body_nonterminal2;
            New_Decl_Item_Or_Body.decl_item_part := decl_item_nonterminal_ptr(New_Decl_Item);
            New_Decl_Item_Or_Body_S1 := new decl_item_or_body_s1_nonterminal1;
            New_Decl_Item_Or_Body_S1.decl_item_or_body_part := decl_item_or_body_nonterminal_ptr(New_Decl_Item_Or_Body);
            New_Decl_Part := new decl_part_nonterminal2;
            New_Decl_Part.decl_item_or_body_s1_part := decl_item_or_body_s1_nonterminal_ptr(New_Decl_Item_Or_Body_S1);
            Decls := decl_part_nonterminal_ptr(New_Decl_Part);
         end if;   --processing range identifier
         
         --now must make a new stop identifier
         Stop_Identifier := new Parseable_Token;
         Stop_Identifier.Line := 0;   --not worth it to set these to their correct values
         Stop_Identifier.Column := 0;
         Stop_Identifier.Token_String := new String'(New_Range_Identifier.Token_String.all & "_stop");
         Stop_Identifier.Token_Type := IDENTIFIER_Token;
         --try and use a meaningful identifier name, but if it happens to be already declared then
         --just use a unique one
         Search_And_Insert(Decls.all, Stop_Identifier, Decl_Search_Result);
         if Decl_Search_Result = Found_In_Decls then
            Create_And_Add_Unique_Identifier(Decls.all, Stop_Identifier);         
         end if; 
         Mark_For_Loops(This.basic_loop_part.all, Decls);   --check for nesting
      else   --this is not a for loop, but might be one inside it, continue checking
         Mark_For_Loops(This.basic_loop_part.all, Decls);
      end if;
   end Mark_For_Loops;

   ---------------
   -- Translate --
   ---------------
   
  --label opt iteration basic_loop id_opt ;
   procedure Translate (This : in out loop_stmt_nonterminal) is
   exp1, exp2, Start_Exp, Stop_Exp : Simple_Expression_Nonterminal_Ptr;
   Loop_Control_Var, Comp_Op_String, Change_Op_String : Unbounded_String;
   begin
      --ignore optional label
      if Is_While_Loop(This.iteration_part.all) then
         Translate(This.iteration_part.all);
         my_new_line;
         put("{");
         Inc_Indent;
         my_new_line;
         Translate_Statements(This.basic_loop_part.all);
         Dec_Indent;
         my_new_line;
         put("}");
         my_new_line;
      elsif Is_For_Loop(This.iteration_part.all) then
           
         --FOR I IN A..B LOOP stmts END LOOP becomes
         --I = A;   (decls for these previously added)
         --I_stop = B;
         --while I <= I_stop
         --{
         --   stmts
         --   I = I+1;
         --}
         --(with the obvious changes for reverse loops)
         
         exp1 := Get_Left_Expression(This.iteration_part.all);
         exp2 := Get_Right_Expression(This.iteration_part.all);
         Loop_Control_Var := To_Unbounded_String(To_Upper(Get_Range_Identifier(This.iteration_part.all).Token_String.all));
         Start_Exp := exp1;
         Stop_Exp := exp2;
         Comp_Op_String := To_Unbounded_String("<=");
         Change_Op_String := To_Unbounded_String("+");
         if Is_Reverse_For_Loop(This.iteration_part.all) then
            Start_Exp := exp2;
            Stop_Exp := exp1;
            Comp_Op_String := To_Unbounded_String(">=");
            Change_Op_String := To_Unbounded_String("-");
         end if;
         
         my_new_line; 
         put_with_space(Loop_Control_Var);
         put_with_space("=");
         Translate(Start_Exp.all);
         put(";");
         my_new_line;
         put_with_space(Loop_Control_Var & "_STOP");
         put_with_space("=");
         Translate(Stop_Exp.all);
         put(";");
         my_new_line;
         put_with_space("while (");
         put_with_space(Loop_Control_Var);
         put_with_space(Comp_Op_String);
         put_with_space(Loop_Control_Var & "_STOP");
         put_with_space(")");
         my_new_line;
         put("{");
         Inc_Indent;
         my_new_line;
         Translate_Statements(This.basic_loop_part.all);
         put_with_space(Loop_Control_Var);
         put_with_space("=");
         put_with_space(Loop_Control_Var);
         put_with_space(Change_Op_String);
         put_with_space("1;");
         Dec_Indent;
         my_new_line;
         put("}");
         my_new_line;
      else   --basic loop
         put_with_space("while (true)");
         my_new_line;
         put("{");
         Inc_Indent;
         my_new_line;
         Translate_Statements(This.basic_loop_part.all);
         Dec_Indent;
         my_new_line;
         put("}");
         my_new_line;
      end if;
      --ignore optional identifier and ';'
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --could be empty, that's OK
   procedure Translate (This : in out label_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --labels ignored
   procedure Translate (This : in out label_opt_nonterminal2) is
   begin
      null;
   end Translate;
   
   -------------------------
   -- Is_Reverse_For_Loop --
   -------------------------
   function Is_Reverse_For_Loop(This : in iteration_nonterminal1) return boolean is
   begin
      return false;
   end Is_Reverse_For_Loop;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   --empty, should never be called
   function Get_Left_Expression(This : in iteration_nonterminal1) return Simple_Expression_Nonterminal_Ptr is
   begin
      return null;
   end Get_Left_Expression;
   
   -------------------------
   -- Get_Right_Expression --
   -------------------------
   --empty, should never be called
   function Get_Right_Expression(This : in iteration_nonterminal1) return Simple_Expression_Nonterminal_Ptr is
   begin
      return null;
   end Get_Right_Expression;
   
   -------------------
   -- Is_While_Loop --
   -------------------
   function Is_While_Loop (This : in iteration_nonterminal1) return boolean is
   begin
      return false;
   end Is_While_Loop;
   
   -----------------
   -- Is_For_Loop --
   -----------------
   function Is_For_Loop (This : in iteration_nonterminal1) return boolean is
   begin
      return false;
   end Is_For_Loop;
   
   --------------------------
   -- Get_Range_Identifier --
   --------------------------
   function Get_Range_Identifier(This: in iteration_nonterminal1) return Parseable_Token_Ptr is
   begin
      return null;
   end;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out iteration_nonterminal1; From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ------------------------------
   -- Set_Range_Identifier --
   ------------------------------
   --should never be called
   procedure Set_Range_Identifier(This : in out iteration_nonterminal1; Id : in Parseable_Token_Ptr) is
   begin
      null;
   end Set_Range_Identifier;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out iteration_nonterminal1) is
   begin
      null;
   end Translate;
   
   -------------------------
   -- Is_Reverse_For_Loop --
   -------------------------
   function Is_Reverse_For_Loop(This : in iteration_nonterminal2) return boolean is
   begin
      return false;
   end Is_Reverse_For_Loop;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   --for a WHILE loop, should never be called
   function Get_Left_Expression(This : in iteration_nonterminal2) return Simple_Expression_Nonterminal_Ptr is
   begin
      return null;
   end Get_Left_Expression;
   
   --------------------------
   -- Get_Range_Identifier --
   --------------------------
   function Get_Range_Identifier(This: in iteration_nonterminal2) return Parseable_Token_Ptr is
   begin
      return null;
   end;
   
   -------------------------
   -- Get_Right_Expression --
   -------------------------
   --for a WHILE loop, should never be called
   function Get_Right_Expression(This : in iteration_nonterminal2) return Simple_Expression_Nonterminal_Ptr is
   begin
      return null;
   end Get_Right_Expression;
   
   -------------------
   -- Is_While_Loop --
   -------------------
   function Is_While_Loop (This : in iteration_nonterminal2) return boolean is
   begin
      return true;
   end Is_While_Loop;
   
   -------------------
   -- Is_For_Loop --
   -------------------
   function Is_For_Loop (This : in iteration_nonterminal2) return boolean is
   begin
      return false;
   end Is_For_Loop;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out iteration_nonterminal2; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.condition_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ------------------------------
   -- Set_Range_Identifier --
   ------------------------------
   --should never be called
   procedure Set_Range_Identifier(This : in out iteration_nonterminal2; Id : in Parseable_Token_Ptr) is
   begin
      null;
   end Set_Range_Identifier;
  
   ---------------
   -- Translate --
   ---------------
   --while loops, pretty straightforward
   procedure Translate (This : in out iteration_nonterminal2) is
   begin
      Translate(This.WHILE_part.all);
      put_with_space("(");
      Translate(This.condition_part.all);
      put_with_space(")");      
   end Translate;

   -------------------------
   -- Is_Reverse_For_Loop --
   -------------------------
   function Is_Reverse_For_Loop(This : in iteration_nonterminal3) return boolean is
   begin
      return not Is_Empty(This.reverse_opt_part.all);
   end Is_Reverse_For_Loop;
   
   -------------------------
   -- Get_Left_Expression --
   -------------------------
   function Get_Left_Expression(This : in iteration_nonterminal3) return Simple_Expression_Nonterminal_Ptr is
   begin
      return Get_Left_Expression(This.discrete_range_part.all);
   end Get_Left_Expression;
   
   --------------------------
   -- Get_Range_Identifier --
   --------------------------
   function Get_Range_Identifier(This: in iteration_nonterminal3) return Parseable_Token_Ptr is
   begin
      return This.iter_part_part.IDENTIFIER_part;
   end;
   
   -------------------------
   -- Get_Right_Expression --
   -------------------------
   function Get_Right_Expression(This : in iteration_nonterminal3) return Simple_Expression_Nonterminal_Ptr is
   begin
      return Get_Right_Expression(This.discrete_range_part.all);
   end Get_Right_Expression;
   
   -------------------
   -- Is_While_Loop --
   -------------------
   function Is_While_Loop (This : in iteration_nonterminal3) return boolean is
   begin
      return false;
   end Is_While_Loop;
   
   -------------------
   -- Is_For_Loop --
   -------------------
   function Is_For_Loop (This : in iteration_nonterminal3) return boolean is
   begin
      return true;
   end Is_For_Loop;
   
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out iteration_nonterminal3; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.iter_part_part.all, From => From, To => To);
      Change_Identifiers(This => This.discrete_range_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ------------------------------
   -- Set_Range_Identifier --
   ------------------------------
   procedure Set_Range_Identifier(This : in out iteration_nonterminal3; Id : in Parseable_Token_Ptr) is
   begin
      This.iter_part_part.IDENTIFIER_part := Id;
   end Set_Range_Identifier;
   
   ---------------
   -- Translate --
   ---------------
   --for a FOR loop, should never be called
   procedure Translate (This : in out iteration_nonterminal3) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out iter_part_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifier(This => This.identifier_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out iter_part_nonterminal) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in reverse_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;

   ---------------
   -- Translate --
   ---------------
   --could be empty, OK
   procedure Translate (This : in out reverse_opt_nonterminal1) is
   begin
      null;
   end Translate;

   --------------
   -- Is_Empty --
   --------------
   function Is_Empty(This : in reverse_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out reverse_opt_nonterminal2) is
   begin
      Translate(This.REVERSE_part.all);
   end Translate;
      
   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure Change_Identifiers(This : in out basic_loop_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.statement_s_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops(This : in basic_loop_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
   end Mark_For_Loops;
   
   --------------------------
   -- Translate_Statements --
   --------------------------

   procedure Translate_Statements (This : in out basic_loop_nonterminal) is
   begin
      Translate(This.statement_s_part.all);
   end Translate_Statements;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out basic_loop_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out id_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out id_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   --only empty blocks supported, so don't do anything here
   procedure Change_Identifiers(This : in out block_nonterminal; From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in block_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.block_body_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out block_nonterminal) is
   begin
      --ignore optional label
      Translate(This.block_decl_part.all);
      Translate(This.block_body_part.all);
      Translate(This.END_part.all);
      --ignore optional id
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --OK if empty
   procedure Translate (This : in out block_decl_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out block_decl_nonterminal2) is
   begin
      Translate(This.DECLARE_part.all);
      Translate(This.decl_part_part.all);
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------
   procedure Mark_For_Loops (This : in block_body_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.handled_stmt_s_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out block_body_nonterminal) is
   begin
      if Proc_Nesting_Level = 1 then
         put_line("task main()");
         Translate(This.BEGIN_part.all);
      end if;
      Translate(This.handled_stmt_s_part.all); 
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in handled_stmt_s_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.statement_s_part.all, Decls);
   end Mark_For_Loops;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out handled_stmt_s_nonterminal) is
   begin
      Translate(This.statement_s_part.all); 
      Translate(This.except_handler_part_opt_part.all);
      
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --Must be empty for successful translation
   procedure Translate (This : in out except_handler_part_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_handler_part_opt_nonterminal2) is
   begin
      Translate(This.except_handler_part_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  exit_stmt_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.when_opt_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------
   procedure Translate (This : in out exit_stmt_nonterminal) is
   begin
      if not Is_Empty(This.when_opt_part.all) then
         my_new_line;
         put_with_space("if (");
         Translate_Condition(This.when_opt_part.all);
         put(")");
         Inc_Indent;
         my_new_line;
      end if;
      put("break");
      Translate(This.SEMICOLON_part.all);
      Dec_Indent;
      my_new_line;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  when_opt_nonterminal1;
      From, To : in Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   --------------------------
   -- Translate_Condition --
   --------------------------
   --should never be called
   procedure Translate_Condition (This : in when_opt_nonterminal1) is
   begin
      null;
   end Translate_Condition;
   
   ---------------
   -- Is_Empty  --
   ---------------

   function Is_Empty (This : in when_opt_nonterminal1) return boolean is
   begin
      return true;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out when_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  when_opt_nonterminal2;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This.condition_part.all, From => From, To => To);
   end Change_Identifiers;
   
   --------------------------
   -- Translate_Condition --
   --------------------------
   procedure Translate_Condition (This : in when_opt_nonterminal2) is
   begin
      Translate(This.condition_part.all);
   end Translate_Condition;
   
  ----------------
   -- Is_Empty  --
   ---------------

   function Is_Empty (This : in when_opt_nonterminal2) return boolean is
   begin
      return false;
   end Is_Empty;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out when_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  return_stmt_nonterminal1; From, To : Parseable_Token_Ptr) is
   begin
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out return_stmt_nonterminal1) is
   begin
      Translate(This.RETURN_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  return_stmt_nonterminal2; From, To : Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.expression_part.all, From => From, To => To);
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out return_stmt_nonterminal2) is
   begin
      Translate(This.RETURN_part.all);
      Translate(This.expression_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out goto_stmt_nonterminal) is
   begin
      Translate(This.GOTO_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --Things like "procedure foo (...) ; "
   procedure Translate (This : in out subprog_decl_nonterminal1) is
   Line, Column : Integer;
   begin
      Line := This.SEMICOLON_part.line;
      Column := This.SEMICOLON_part.line;
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada subprogram headers without bodies are not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   --procedure foo (...) is generic;
   procedure Translate (This : in out subprog_decl_nonterminal2) is
   Line, Column : Integer;
   begin
      Line := This.SEMICOLON_part.line;
      Column := This.SEMICOLON_part.column;
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => ": Ada generics are not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subprog_decl_nonterminal3) is
   Line, Column : Integer;
   begin
      Line := This.ABSTRACT_part.line;
      Column := This.ABSTRACT_part.column;
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada 'abstract' keyword not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
   end Translate;

   ---------------
   -- Translate --
   ---------------
   --procedure foo (optional formals)
   procedure Translate (This : in out subprog_spec_nonterminal1) is
   Line, Column : Integer;
   Proc_Name : Parseable_Token_ptr;
   Info_Rec : Lego_Builtins.Procedure_Info_Record_Type;
   Formal_Parameter_Array : Lego_Builtins.Formal_Parameter_Array_Type;
   Start_Slot : Integer := 1;   --for building formal parameter list for user-defined procedures
   
   begin
      case Proc_Nesting_Level is
         when 0 =>
            put(File => Standard_Error, 
               Item => "Internal error in translator (procedure Translate(subprog_spec_nonterminal1)),");
            new_line(File => Standard_Error);
            put(File => Standard_Error, 
               Item => "please report this error to the program maintainer at your site.");
            new_line(File => Standard_Error);
      
         when 1 =>   --top level procedure, don't translate now, eventually
            null;    --replace with "task main" once user-defined procs parsed
            
         when 2 =>   --user defined procedure, turn it into a function and
                     --translate the formals
                     
            --first check for name clash with predefined Ada/Mindstorms procedures
            Proc_Name := Get_Simple_Name(This.compound_name_part.all);
            Line := Proc_Name.Line;
            Column := Proc_Name.column;
            if Is_Ada_Mindstorms_Identifier(Proc_Name.Token_String.all) then
               Error_Msg_Prefix(Line, Column);
               put(File => Standard_Error, Item => " Procedure ");
               put(File => Standard_Error, Item => Proc_Name.Token_String.all);
               put(File => Standard_Error, Item => " has the same name as a procedure that is ");
               new_line(File => Standard_Error);
               put(File => Standard_Error, Item => "already a part of Ada/Mindstorms (look in lego.ads for details).");
               new_line(File => Standard_Error);
               put(File => Standard_Error, Item => "Change the name of the procedure and recompile.");                
               new_line(File => Standard_Error);
               raise Parse_Error_Exception;
            else
               --add new proc to proc info table
               Info_Rec.Name := To_Unbounded_String(Proc_Name.Token_String.all);
               Info_Rec.Arity := Get_Arity(This.formal_part_opt_part.all);
               if Info_Rec.Arity > Lego_Builtins.Max_Procedure_Arity then
                  Error_Msg_Prefix(Line, Column);
                  put(File => Standard_Error, Item => " Procedure ");
                  put(File => Standard_Error, Item => Proc_Name.Token_String.all);
                  put(File => Standard_Error, Item => " has too many parameters (max is ");
                  put(File => Standard_Error, Item => Lego_Builtins.Max_Procedure_Arity, width => 0);
                  put(File => Standard_Error, Item => ") for Ada/Mindstorms");
                  new_line(File => Standard_Error);
                  put(File => Standard_Error, Item => "Reduce the number of parameters and recompile.");
                  new_line(File => Standard_Error);
                  raise Parse_Error_Exception;
               end if;
                  
               Build_Formal_Parameter_List(This.formal_part_opt_part.all, Formal_Parameter_Array, Start_Slot);
               Info_Rec.Formal_Parameters := Formal_Parameter_Array;
               Add_To_Proc_Info_Table(Info_Rec, Line, Column);
      
               --and do the translation
               put_with_space("void");
               Translate(This.compound_name_part.all);
               Translate(This.formal_part_opt_part.all);
               my_new_line;
            end if;
            
         when others =>
            Line := This.PROCEDURE_part.Line;
            Column := This.PROCEDURE_part.Column;
            Error_Msg_Prefix(Line, Column);
            put(File => Standard_Error, Item => " Nesting of user-defined procedures not supported.  ");
            new_line(File => Standard_Error);
            raise Parse_Error_Exception;
      end case;
 
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subprog_spec_nonterminal2) is
   begin
      Translate(This.FUNCTION_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subprog_spec_nonterminal3) is
   begin
      Translate(This.FUNCTION_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out designator_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out designator_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   --no formal parameters
   procedure Build_Formal_Parameter_List(This : in formal_part_opt_nonterminal1;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      null;
   end Build_Formal_Parameter_List;
      
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in formal_part_opt_nonterminal1) return integer is
   begin
      return 0;
   end Get_Arity;
   
   ---------------
   -- Translate --
   ---------------
   --empty formal parameter declaration
   procedure Translate (This : in out formal_part_opt_nonterminal1) is
   begin
      put("()");
   end Translate;

   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in formal_part_opt_nonterminal2;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.formal_part_part.all, Formal_Parameter_Array,
         Next_Slot);
   end Build_Formal_Parameter_List;

   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in formal_part_opt_nonterminal2) return integer is
   begin
      return Get_Arity(This.formal_part_part.all);
   end Get_Arity;
   
   ---------------
   -- Translate --
   ---------------
   --one or more formal parameter declarations
   procedure Translate (This : in out formal_part_opt_nonterminal2) is
   begin
      Translate(This.formal_part_part.all);
   end Translate;

   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in formal_part_nonterminal;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.param_s_part.all, Formal_Parameter_Array,
         Next_Slot);
   end Build_Formal_Parameter_List;
              
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in formal_part_nonterminal) return integer is
   begin
      return Get_Arity(This.param_s_part.all);
   end Get_Arity;
   
   ---------------
   -- Translate --
   ---------------
   -- ( formal parameters )
   procedure Translate (This : in out formal_part_nonterminal) is
   begin
      Translate(This.L_PAREN_part.all);
      Translate(This.param_s_part.all);
      Translate(This.R_PAREN_part.all);
   end Translate;

   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in param_s_nonterminal1;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.param_part.all, Formal_Parameter_Array,
         Next_Slot);
   end Build_Formal_Parameter_List;
         
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in param_s_nonterminal1) return integer is
   begin
      return Get_Arity(This.param_part.all);
   end Get_Arity;
      
   ---------------
   -- Translate --
   ---------------
   --one formal parameter declaration
   procedure Translate (This : in out param_s_nonterminal1) is
   begin
      Translate(This.param_part.all);
   end Translate;

   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in param_s_nonterminal2;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.param_s_part.all, Formal_Parameter_Array,
         Next_Slot);
      Build_Formal_Parameter_List(This.param_part.all, Formal_Parameter_Array,
         Next_Slot);
   end Build_Formal_Parameter_List;
               
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in param_s_nonterminal2) return integer is
   begin
      return (Get_Arity(This.param_part.all) + Get_Arity(This.param_s_part.all));
   end Get_Arity;
      
   ---------------
   -- Translate --
   ---------------
   --multiple formal parameter declarations
   procedure Translate (This : in out param_s_nonterminal2) is
   begin
      Translate(This.param_s_part.all);
      put_with_space(",");   --semicolon connecting Ada formals replaced with comma for NQC
      Translate(This.param_part.all);
   end Translate;

   --for looking down the tree and determining if a mode is OUT
   
   --empty mode spec
   function Is_Out(This : in mode_nonterminal1) return boolean is
   Ignored : mode_nonterminal1;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return false;
   end Is_Out;
   
   --IN only
   function Is_Out(This : in mode_nonterminal2) return boolean is
   Ignored : mode_nonterminal2;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return false;
   end Is_Out;
   
   --OUT only
   function Is_Out(This : in mode_nonterminal3) return boolean is
   Ignored : mode_nonterminal3;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return true;
   end Is_Out;
   
   --IN OUT
   function Is_Out(This : in mode_nonterminal4) return boolean is
   Ignored : mode_nonterminal4;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return true;
   end Is_Out;
  
   --ACCESS
   function Is_Out(This : in mode_nonterminal5) return boolean is
   Ignored : mode_nonterminal5;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return false;
   end Is_Out;
   
   --simple name, might be supported type
   function Is_Supported_Variable_Type(This : in mark_nonterminal1) return boolean is
   begin
      return Is_Supported_Predefined_Scalar_Type(This.simple_name_part.all);
   end Is_Supported_Variable_Type;
   
   --has a tick mark, can't be supported type
   function Is_Supported_Variable_Type(This : in mark_nonterminal2) return boolean is
   Ignored : mark_nonterminal2;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return false;
   end Is_Supported_Variable_Type;
   
   --has a dot, can't be supported type
   function Is_Supported_Variable_Type(This : in mark_nonterminal3) return boolean is
   Ignored : mark_nonterminal3;
   begin
      Ignored := This;   --avoid warning for unreferenced parameter
      return false;
   end Is_Supported_Variable_Type;
               
   ---------------------------------
   -- Build_Formal_Parameter_List --
   ---------------------------------
   procedure Build_Formal_Parameter_List(This : in param_nonterminal;
      Formal_Parameter_Array : in out Lego_Builtins.Formal_Parameter_Array_Type; Next_Slot : in out integer) is
   begin
      Build_Formal_Parameter_List(This.def_id_s_part.all, Formal_Parameter_Array,
         Next_Slot);
   end Build_Formal_Parameter_List;
   
   ---------------
   -- Get_Arity --
   ---------------
   function Get_Arity(This : in param_nonterminal) return integer is
   begin
      return Get_Arity(This.def_id_s_part.all);
   end Get_Arity;
               
   ---------------
   -- Translate --
   ---------------
   -- translate a formal parameter declaration
   -- id1[,id2 ...] : [mode] name_list [initialization]
   -- becomes int[&] id1[, int[&] id2 ...]
   procedure Translate (This : in out param_nonterminal) is
   Line, Column : Integer;
   Reference : Boolean;
   begin
      --pass by reference if out parameter
      if Is_Out(This.mode_part.all) then
         Reference := true;
      else
         Reference := false;
      end if;
      
      --formal parameter types restricted to those for variables
      if not Is_Supported_Variable_Type(This.mark_part.all) then
         Line := This.COLON_part.line;
         Column := This.COLON_part.column;
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " This type of formal parameter not supported.  ");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      end if;
      
      --formal parameter default values not supported
      if not Is_Empty(This.init_opt_part.all) then
         Line := This.COLON_part.line;
         Column := This.COLON_part.column;
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => " Default values for formal parameters not supported.  ");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;
      end if;

      --translate list of formal parameter names
      Translate_Formal_Parameters(This.def_id_s_part.all, Reference);

   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mode_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mode_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mode_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mode_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out mode_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subprog_spec_is_push_nonterminal) is
   begin
      Translate(This.subprog_spec_part.all);
      Translate(This.IS_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   --procedure (...) is {decls} begin {statements} end [id]
   procedure Translate (This : in out subprog_body_nonterminal) is
   Line, Column : Integer;
   begin
      Proc_Nesting_Level := Proc_Nesting_Level + 1;
      if Proc_Nesting_Level = 1 then
         Type_Decl_Lists.Initialize(Global_Type_Decls);
      elsif Proc_Nesting_Level = 2 then
         Type_Decl_Lists.Initialize(Local_Type_Decls);
      else
         Line := This.SEMICOLON_part.line;
         Column := This.SEMICOLON_part.column;
         Error_Msg_Prefix(Line, Column);
         put(File => Standard_Error, Item => "Procedures can't nest this deeply in Ada/Mindstorms;");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "only the main procedure can have procedures inside it.");
         new_line(File => Standard_Error);
         put(File => Standard_Error, Item => "Rewrite your program to remove the procedure nesting and recompile.");
         new_line(File => Standard_Error);
         raise Parse_Error_Exception;         
      end if;
      
      Translate(This.subprog_spec_is_push_part.all);
      
      --Each 'for' loop in a procedure requires two new identifier
      --declarations.  This is taken care of here.  The 'Mark_For_Loops' walks the tree
      --to find 'for' loops.  When it finds one, it checks the range identifier for uniqueness,
      --creates a stop identifier and checks that for uniqueness, then adds the identifiers to the decl part.
      
--      FOR I in A..B LOOP
--         stmts;
--      END LOOP
--      
--      becomes
--      
--      int i, i_stop; (in decl section)
--      ...
--      i := A;
--      i_stop := B;
--      while i <= i_stop
--      {
--         stmts;
--         i++;
--      }
--      
--      similar for FOR I in reverse A..B LOOP
      
      Mark_For_Loops(This.block_body_part.all, This.decl_part_part);

      my_new_line;
      if Proc_Nesting_Level > 1 then
         put_with_space("{");
         Inc_Indent;
      end if;
      my_new_line;
      Translate(This.decl_part_part.all);  
      Translate(This.block_body_part.all); 
      my_new_line;
      Translate(This.END_part.all);   -- calls dec_indent
      my_new_line;
      --ignore id_opt part
      --ignore semicolon
      Proc_Nesting_Level := Proc_Nesting_Level - 1;
   
   end Translate;

   ------------------------
   -- Change_Identifiers --
   ------------------------
   procedure change_identifiers(This : in out  procedure_call_nonterminal;
      From, To : in Parseable_Token_Ptr) is
   begin
      Change_Identifiers(This => This.name_part.all, From => From, To => To);
      null;
   end Change_Identifiers;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out procedure_call_nonterminal) is
   begin
      Translate(This.name_part.all);
      if Get_Arity(This.name_part.all) = 0 then
         put_with_space("()");   --NQC requires parentheses for 0-arity calls
      end if;
      Translate(This.SEMICOLON_part.all);
      my_new_line;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pkg_decl_nonterminal1) is
   begin
      Translate(This.pkg_spec_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pkg_decl_nonterminal2) is
   begin
      Translate(This.generic_pkg_inst_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pkg_spec_nonterminal) is
   begin
      Translate(This.PACKAGE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out private_part_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out private_part_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out c_id_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out c_id_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out pkg_body_nonterminal) is
   begin
      Translate(This.PACKAGE_part.all);   
   --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out private_type_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out limited_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out limited_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out use_clause_nonterminal1) is
   begin
      Translate(This.USE_part.all);
      Check_For_Supported_Packages(This.name_s_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out use_clause_nonterminal2) is
   begin
      Translate(This.USE_part.all);
      Translate(This.TYPE_part.all);
      --more tree here
   end Translate;

   ----------------------------------
   -- Check_For_Supported_Packages --
   ----------------------------------

   procedure Check_For_Supported_Packages (This : in name_s_nonterminal1) is
   begin
      Check_For_Supported_Package(This.name_part.all);
   end Check_For_Supported_Packages;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_s_nonterminal1) is
   begin
      null;
   end Translate;

   ----------------------------------
   -- Check_For_Supported_Packages --
   ----------------------------------

   procedure Check_For_Supported_Packages (This : in name_s_nonterminal2) is
   begin
      Check_For_Supported_Packages(This.name_s_part.all);
      Check_For_Supported_Package(This.name_part.all);
   end Check_For_Supported_Packages;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out name_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_decl_nonterminal1) is
   Line, Column : Integer;
   begin
      Line := This.COLON_part.Line;
      Column := This.COLON_part.Column;
      put(File => Standard_Error, Item => " Ada rename statements not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;


   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_decl_nonterminal2) is
   Line, Column : Integer;
   begin
      Line := This.COLON_part.Line;
      Column := This.COLON_part.Column;
      Error_Msg_Prefix(Line, Column);
      put(File => Standard_Error, Item => " Ada rename statements not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_decl_nonterminal3) is
   begin
      Translate(This.rename_unit_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_unit_nonterminal1) is
   begin
      --more tree here
      Translate(This.renaming_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_unit_nonterminal2) is
   begin
      --more tree here
      Translate(This.renaming_part.all);
      --more tree here
   end Translate;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_unit_nonterminal3) is
   begin
      --more tree here
      Translate(This.renaming_part.all);
      --more tree here
   end Translate;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rename_unit_nonterminal4) is
   begin
      --more tree here
      Translate(This.renaming_part.all);
      --more tree here
   end Translate;
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out renaming_nonterminal) is
   begin
      Translate(This.RENAMES_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_decl_nonterminal) is
   begin
      Translate(This.task_spec_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_spec_nonterminal1) is
   begin
      Translate(This.TASK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_spec_nonterminal2) is
   begin
      Translate(This.TASK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_def_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_def_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_private_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_private_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out task_body_nonterminal) is
   begin
      Translate(This.TASK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_decl_nonterminal) is
   begin
      Translate(This.prot_spec_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_spec_nonterminal1) is
   begin
      Translate(This.PROTECTED_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_spec_nonterminal2) is
   begin
      Translate(This.PROTECTED_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_def_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_private_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_private_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_decl_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_elem_decl_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_elem_decl_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_elem_decl_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_elem_decl_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_body_nonterminal) is
   begin
      Translate(This.PROTECTED_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_body_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_body_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_body_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_body_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out prot_op_body_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_decl_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_decl_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_decl_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_decl_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_body_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_body_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_body_part_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_body_part_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rep_spec_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rep_spec_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_call_nonterminal) is
   begin
      null;
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in accept_stmt_nonterminal1; 
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out accept_stmt_nonterminal1) is
   begin
      Translate(This.accept_hdr_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------

   procedure Mark_For_Loops (This : in accept_stmt_nonterminal2;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      Mark_For_Loops(This.handled_stmt_s_part.all, Decls);
   end Mark_For_Loops;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out accept_stmt_nonterminal2) is
   begin
      Translate(This.accept_hdr_part.all);
      Translate(This.DO_part.all);
      Translate(This.handled_stmt_s_part.all);
      Translate(This.END_part.all);
      Translate(This.id_opt_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out accept_hdr_nonterminal) is
   begin
      Translate(This.ACCEPT_part.all);
      Translate(This.entry_name_part.all);
      Translate(This.formal_part_opt_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_name_nonterminal1) is
   begin
      Translate(This.simple_name_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out entry_name_nonterminal2) is
   begin
      Translate(This.entry_name_part.all);
      Translate(This.L_PAREN_Part.all);
      Translate(This.expression_part.all);
      Translate(This.R_PAREN_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out delay_stmt_nonterminal1) is
   begin
      Translate(This.DELAY_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out delay_stmt_nonterminal2) is
   begin
      Translate(This.DELAY_part.all);
      --more tree here
   end Translate;

   ---------------------
   -- Mark_For_Loops --
   ---------------------
   --need to replace this with dispatched methods if SELECT statements are ever supported
   procedure Mark_For_Loops (This : in select_stmt_nonterminal;
      Decls : in out decl_part_nonterminal_ptr) is
   begin
      null;
   end Mark_For_Loops;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_stmt_nonterminal1) is
   begin
      Translate(This.select_wait_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_stmt_nonterminal2) is
   begin
      Translate(This.async_select_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_stmt_nonterminal3) is
   begin
      Translate(This.timed_entry_call_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_stmt_nonterminal4) is
   begin
      Translate(This.cond_entry_call_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_wait_nonterminal) is
   begin
      Translate(This.SELECT_part1.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out guarded_select_alt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out guarded_select_alt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out or_select_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out or_select_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_alt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_alt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out select_alt_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out delay_or_entry_alt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out delay_or_entry_alt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out async_select_nonterminal) is
   begin
      Translate(This.SELECT_part1.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out timed_entry_call_nonterminal) is
   begin
      Translate(This.SELECT_part1.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out cond_entry_call_nonterminal) is
   begin
      Translate(This.SELECT_part1.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out stmts_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out stmts_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out abort_stmt_nonterminal) is
   begin
      Translate(This.abort_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compilation_nonterminal1) is
   begin
      null;   --empty compilation unit
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compilation_nonterminal2) is
   begin
      Translate(This.compilation_part.all);  
      Translate(This.comp_unit_part.all);    --primary translation path
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out compilation_nonterminal3) is
   begin
      Translate(This.pragma_sym_part.all);
      Translate(This.pragma_s_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_unit_nonterminal1) is
   begin
      Translate(This.context_spec_part.all);
      Translate(This.private_opt_part.all);
      Translate(This.unit_part.all);
      Translate(This.pragma_s_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_unit_nonterminal2) is
   begin
      Translate(This.private_opt_part.all);
      Translate(This.unit_part.all);
      Translate(This.pragma_s_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out private_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out private_opt_nonterminal2) is
   begin
      Translate(This.PRIVATE_part.all);
   end Translate;
   
   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out context_spec_nonterminal1) is
   begin
      Translate(This.with_clause_part.all);
      Translate(This.use_clause_opt_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out context_spec_nonterminal2) is
   begin
      Translate(This.context_spec_part.all);
      Translate(This.with_clause_part.all);
      Translate(This.use_clause_opt_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out context_spec_nonterminal3) is
   begin
      Translate(This.context_spec_part.all);
      Translate(This.pragma_sym_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out with_clause_nonterminal) is
   begin
      Check_For_Supported_Package(This.c_name_list_part.all);      
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out use_clause_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out use_clause_opt_nonterminal2) is
   begin
      Translate(This.use_clause_opt_part.all);
      Translate(This.use_clause_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal1) is
   begin
      Translate(This.pkg_decl_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal2) is
   begin
       Translate(This.pkg_body_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal3) is
   begin
       Translate(This.subprog_decl_part.all);   
   end Translate;


   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal4) is
   begin
       Translate(This.subprog_body_part.all);   --primary translation path
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal5) is
   begin
       Translate(This.subunit_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal6) is
   begin
       Translate(This.generic_decl_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out unit_nonterminal7) is
   begin
       Translate(This.rename_unit_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subunit_nonterminal) is
   begin
      Translate(This.SEPARATE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subunit_body_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subunit_body_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subunit_body_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subunit_body_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_stub_nonterminal1) is
   begin
      Translate(This.TASK_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_stub_nonterminal2) is
   begin
      Translate(This.PACKAGE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_stub_nonterminal3) is
   begin
      Translate(This.SEPARATE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out body_stub_nonterminal4) is
   begin
      Translate(This.PROTECTED_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out exception_decl_nonterminal) is
   begin
      Translate(This.EXCEPTION_part.all);
      --more tree here
   end Translate;


   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_handler_part_nonterminal1) is
   begin
      Translate(This.EXCEPTION_part.all);   --terminates translation
      Translate(This.exception_handler_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_handler_part_nonterminal2) is
   begin
      Translate(This.except_handler_part_part.all);
      Translate(This.exception_handler_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out exception_handler_nonterminal1) is
   begin
      Translate(This.WHEN_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out exception_handler_nonterminal2) is
   begin
      Translate(This.WHEN_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_choice_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_choice_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_choice_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out except_choice_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out raise_stmt_nonterminal) is
   begin
      Translate(This.raise_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out requeue_stmt_nonterminal1) is
   begin
      Translate(This.REQUEUE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out requeue_stmt_nonterminal2) is
   begin
      Translate(This.REQUEUE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_decl_nonterminal1) is
   begin
      Translate(This.generic_formal_part_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_decl_nonterminal2) is
   begin
      Translate(This.generic_formal_part_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_part_nonterminal1) is
   begin
      Translate(This.GENERIC_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_part_nonterminal2) is
   begin
      Translate(This.generic_formal_part_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal6) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_formal_nonterminal7) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate
     (This : in out generic_discrim_part_opt_nonterminal1)
   is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate
     (This : in out generic_discrim_part_opt_nonterminal2)
   is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate
     (This : in out generic_discrim_part_opt_nonterminal3)
   is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subp_default_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subp_default_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out subp_default_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal4) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal5) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal6) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal7) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal8) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal9) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_type_def_nonterminal10) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_derived_type_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_derived_type_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_derived_type_nonterminal3) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_subp_inst_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_pkg_inst_nonterminal) is
   begin
      Translate(This.PACKAGE_part.all);
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out generic_inst_nonterminal) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rep_spec_nonterminal1) is
   begin
      Translate(This.attrib_def_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rep_spec_nonterminal2) is
   begin
      Translate(This.record_type_spec_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out rep_spec_nonterminal3) is
   begin
      Translate(This.address_spec_part.all);
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out attrib_def_nonterminal) is
   Line, Column : Integer;
   begin
      Line := This.FOR_part.Line;
      Column := This.FOR_part.Column;
      put(File => Standard_Error, Item => " Ada attribute definitions not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out record_type_spec_nonterminal) is
   Line, Column : Integer;
   begin
      Line := This.FOR_part.Line;
      Column := This.FOR_part.Line;
      put(File => Standard_Error, Item => " Ada record specifications not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out align_opt_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out align_opt_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_loc_s_nonterminal1) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out comp_loc_s_nonterminal2) is
   begin
      null;
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out address_spec_nonterminal) is
   Line, Column : Integer;
   begin
      Line := This.FOR_part.Line;
      Column := This.FOR_part.Column;
      put(File => Standard_Error, Item => " Ada address specifications not supported.  ");
      new_line(File => Standard_Error);
      raise Parse_Error_Exception;
      --more tree here
   end Translate;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (This : in out code_stmt_nonterminal) is
   begin
      Translate(This.qualified_part.all);
      Translate(This.SEMICOLON_part.all);
   end Translate;

end trans_Model;