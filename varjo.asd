;;;; varjo.asd

(asdf:defsystem #:varjo
  :description "Common Lisp -> GLSL Compiler"
  :author "Chris Bagley (Baggers) <techsnuffle@gmail.com>"
  :license "LLGPL"
  :serial t
  :depends-on (#:cl-ppcre #:split-sequence #:alexandria #:named-readtables)
  :components ((:file "package")
               (:file "utils-v")
               (:file "compiler/errors")
               (:file "compiler/types")
               (:file "language/types")
               (:file "compiler/variables")
               (:file "compiler/environment")
               (:file "compiler/structs")
               (:file "compiler/code-object")
               (:file "compiler/functions")
               (:file "language/variables")
               (:file "compiler/macros")
               (:file "language/macros")
               (:file "compiler/string-generation")
               (:file "compiler/stemcells")
               (:file "compiler/compiler")
               (:file "language/special")
               (:file "language/functions")
               (:file "language/textures")
               (:file "compiler/front-end")
               (:file "language/object-printers")))
