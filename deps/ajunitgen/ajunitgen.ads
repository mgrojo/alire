with Ada.Containers.Indefinite_Doubly_Linked_Lists;
with Ada.Text_IO;

package AJUnitGen is

   --  Simple package to generate JUnit-compatible XML reports 
   
   --  Create suites with the constructor function
   --  Add test cases to suites
   
   type Collection is tagged private;   
   
   type Test_Suite (<>) is tagged private;
   
   type Test_Case (<>) is private;
   
   type Outcomes is (Pass, Error, Fail, Skip);
   
   procedure Add_Suite (Col : in out Collection; Suite : Test_Suite'Class);
   
   procedure Add_Case (Suite : in out Test_Suite; Test : Test_Case);
   
   function New_Suite (Name : String) return Test_Suite;
   
   function New_Case (Name      : String;
                      Outcome   : Outcomes := Pass;
                      Classname : String   := "";
                      Message   : String   := "";
                      Output    : String   := "") return Test_Case;
   --  Message is a short attribute message on the reason of not PASS
   --  Output is a multiline text child element (e.g. a trace)
   
   function To_Collection (Suite : Test_Suite) return Collection'Class;
   --  Collection containing a single suite
   
   procedure Write (Col : Collection; File : Ada.Text_IO.File_Type);
   --  Write to an already open file
   
private
   
   type Outcome_Counters is array (Outcomes) of Natural;
   
   type Test_Case (Name_Len, 
                   Class_Len,
                   Msg_Len,
                   Out_Len : Natural) is record
      Name      : String (1 .. Name_Len);
      Outcome   : Outcomes;
      Classname : String (1 .. Class_Len);
      Message   : String (1 .. Msg_Len);
      Output    : String (1 .. Out_Len);
   end record;
   
   package Test_Lists is new Ada.Containers.Indefinite_Doubly_Linked_Lists (Test_Case);
   
   type Test_Suite (Name_Len : Natural) is tagged record
      Name  : String (1 .. Name_Len);
      Tests : Test_Lists.List;
      
      Size     : Natural := 0;
      Counters : Outcome_Counters := (others => 0);
   end record;
   
   package Suite_Lists is new Ada.Containers.Indefinite_Doubly_Linked_Lists (Test_Suite);
   
   type Collection is new Suite_Lists.List with null record;

end AJUnitGen;
