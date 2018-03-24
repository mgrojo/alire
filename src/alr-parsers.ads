with Alire;

with Semantic_Versioning;

package Alr.Parsers with Preelaborate is

   type Allowed_Milestones (Designation_Length : Positive) is record
      Project  : Alire.Designation_String (1 .. Designation_Length);
      Versions : Semantic_Versioning.Version_Set;
   end record;

   function Project_Versions (Spec : String) return Allowed_Milestones;
   --  Either valid set or Constraint_Error
   --  If no version was specified, Any version is returned
   --  Syntax: name[(=|^|~)version]

end Alr.Parsers;