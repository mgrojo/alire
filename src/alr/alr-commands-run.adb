with Ada.Containers;

with Alire.OS_Lib;

with Alr.Commands.Build;
with Alr.Files;
with Alr.OS_Lib;
with Alr.Platform;
with Alr.Utils;

with GNAT.OS_Lib;

package body Alr.Commands.Run is

   use type Ada.Containers.Count_Type;

   Max_Search_Depth : constant := 3;
   --  How many levels to go down looking for built executables,
   --  relative to the build folder of the root crate

   ------------------
   -- Check_Report --
   ------------------

   procedure Check_Report (Cmd      : in out Command;
                           Exe_Name : String) is
      use Ada.Text_IO;

      Found_At : constant Utils.String_Vector :=
        Files.Locate_File_Under (Cmd.Root.Path,
                                 Exe_Name, Max_Depth => Max_Search_Depth);
   begin
      Put ("   " & Exe_Name);
      case Found_At.Length is
         when 0 => Put_Line (" (not found)");
         when 1 => Put_Line (" (found at " & Found_At.First_Element & ")");
         when others =>
            New_Line;
            for Bin of Found_At loop
               Put_Line ("      (found at " & Found_At.First_Element & ")");
            end loop;
      end case;
   end Check_Report;

   -------------
   -- Execute --
   -------------

   overriding
   procedure Execute (Cmd  : in out Command;
                      Args :        AAA.Strings.Vector)
   is
      use type GNAT.Strings.String_Access;

      Name       : constant String := Cmd.Root.Release.Name_Str;
      Declared   : constant Utils.String_Vector :=
                     Cmd.Root.Release.Executables (Platform.Properties);

      ----------
      -- List --
      ----------
      --  List declared/found executables

      procedure List is
         Candidates : constant Utils.String_Vector := Files.Locate_File_Under
           (Cmd.Root.Path,
            Cmd.Root.Release.Default_Executable,
            Max_Depth => Max_Search_Depth);
         --  Candidate default executable
      begin
         if Declared.Is_Empty then
            Put_Line
              ("Crate " & Name &
                 " does not explicitly declares to build any executable");

            if Candidates.Is_Empty then
               Put_Line ("No default executable has been automatically " &
                           "found either by alr");
            else
               Put_Line ("However, the following default executables" &
                           " have been autodetected:");
               Check_Report (Cmd, Cmd.Root.Release.Default_Executable);
            end if;

         else
            Put_Line ("Crate " & Name & " builds these executables:");
            for Exe of Declared loop
               Check_Report (Cmd, Exe);
            end loop;

            --  Default one:
            if not Declared.Contains
              (Cmd.Root.Release.Default_Executable)
              and then
                not Candidates.Is_Empty
            then
               Put_Line ("In addition, the following default-named" &
                           " executables have been detected:");
               Check_Report (Cmd, Cmd.Root.Release.Default_Executable);
            end if;
         end if;
      end List;

   begin
      Cmd.Requires_Valid_Session;

      --  Validation
      if Cmd.List
        and then
          (Args.Count /= 0
           or else
             (Cmd.Args /= null and then Cmd.Args.all /= ""))
      then
         Reportaise_Wrong_Arguments ("Listing is incompatible with execution");
      end if;

      if not Cmd.List and then Args.Count > 1 then
         Reportaise_Wrong_Arguments ("Too many arguments");
      end if;

      declare
         Declared : Utils.String_Vector;
      begin
         Declared := Cmd.Root.Release.Executables (Platform.Properties);

         --  LISTING  --
         if Cmd.List then
            List;
            return;
         end if;

         --  COMPILATION  --
         if not Cmd.No_Compile then
            if not Commands.Build.Execute (Cmd,
                                           Args => AAA.Strings.Empty_Vector,
                                           Export_Build_Env => True)
            then
               Reportaise_Command_Failed ("Build failed");
            end if;
         end if;

         --  EXECUTION  --

         --  Do not default if more than one declared executable. Otherwise use
         --  either the declared executable or, by lack of that, an executable
         --  with the name of the crate.

         if Args.Count = 0 and then Natural (Declared.Length) > 1 then
            Trace.Error
              ("No executable specified but "
               & "the release builds more than one executable:");
            List;
            return;
         end if;

         --  Also do not accept an explicit executable not listed (unless
         --  the release declares no executables and the requested one is
         --  the default one, e.g., same as running without argument).

         if Args.Count = 1
           and then not Declared.Contains (Args (1))
           and then Args (1) /= Cmd.Root.Release.Default_Executable
         then
            Reportaise_Wrong_Arguments
              ("The requested executable is not built by this release"
               & " (see declared list with 'alr run --list')");
         end if;

         --  Proceed to run the requested executable, or if none requested,
         --  the single one declared, or if none, the default named one.

         declare
            use all type Ada.Containers.Count_Type;
            Target_WO_Ext : constant String :=
              (if Args.Count = 1
               then Args (1)
               else
                 (if Declared.Length = 1
                  then Declared.First_Element
                  else Cmd.Root.Release.Default_Executable));

            Target : constant String :=
              (if Alire.OS_Lib.Exe_Suffix /= ""
                and then
                 not Utils.Contains (Target_WO_Ext, Alire.OS_Lib.Exe_Suffix)
               then Target_WO_Ext & Alire.OS_Lib.Exe_Suffix
               else Target_WO_Ext);

            Target_Exes : Utils.String_Vector :=
                            Files.Locate_File_Under
                              (Cmd.Root.Path,
                               Target,
                               Max_Depth => Max_Search_Depth);
         begin

            --  Ensure that a found default executable is indeed executable:

            if Declared.Is_Empty
              and then Target_Exes.Length = 1
              and then not GNAT.OS_Lib.Is_Executable_File
                             (Target_Exes.First_Element)
            then
               Trace.Warning
                 ("Candidate to default executable is not an executable file: "
                  & Target_Exes.First_Element);
               Target_Exes.Clear;
            end if;

            --  Finally launch a single target executable, or error otherwise:

            if Target_Exes.Is_Empty then
               Reportaise_Command_Failed
                 ("Executable " & Utils.Quote (Target) & " not found");
            elsif Natural (Target_Exes.Length) > 1 then
               Trace.Error ("Too many candidates found:");
               for Candid of Target_Exes loop
                  Log (Candid);
               end loop;
            else
               Trace.Detail ("Launching " & Target_Exes.First_Element);
               Trace.Detail ("...");
               OS_Lib.Spawn_Raw (Target_Exes.First_Element, Cmd.Args.all);
            end if;
         end;
      end;
   end Execute;

   ----------------------
   -- Long_Description --
   ----------------------

   overriding
   function Long_Description (Cmd : Command)
                              return AAA.Strings.Vector is
     (AAA.Strings.Empty_Vector
      .Append ("Compiles the crate (unless --skip-compile is specified)"
               & " and then executes the default or given resulting"
               & " executable. ")
      .New_Line
      .Append ("With --list, a list of declared executables is produced"
               & " instead of invoking the compiler, and"
               & " its location (if already built) is given.")
     );

   --------------------
   -- Setup_Switches --
   --------------------

   overriding
   procedure Setup_Switches
     (Cmd    : in out Command;
      Config : in out CLIC.Subcommand.Switches_Configuration)
   is
      use CLIC.Subcommand;
   begin
      Define_Switch
        (Config,
         Cmd.Args'Access,
         "-a:", "--args=",
         "Arguments to pass through (quote them if more than one)",
         Argument => "ARGS");

      Define_Switch
        (Config,
         Cmd.List'Access,
         "", "--list", "List executables produced by current release");

      Define_Switch
        (Config,
         Cmd.No_Compile'Access,
         "-s", "--skip-build", "Skip building step");
   end Setup_Switches;

end Alr.Commands.Run;
