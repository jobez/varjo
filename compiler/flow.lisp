(in-package :varjo)
(in-readtable fn:fn-reader)

;; these are created whenever a new value is, they flow through the code-objects
;; allowing us to detect everywhere a value flows through a program.
;; There are two complications, multiple value return and conditionals
;; - Multiple value return is handled by having a list of flow-identifiers
;; - conditional handled by each flow-identifier contain a list of identifiers
;;   itself. This is the collection of all the values that could flow through
;;   this point.

;;----------------------------------------------------------------------
;; internals

(defun m-flow-id-p (id)
  (typep id 'multi-return-flow-id))

(defun flow-id-p (id)
  (typep id 'flow-identifier))

(defmethod raw-ids ((flow-id flow-identifier))
  (mapcar λ(slot-value _ 'val) (ids flow-id)))


(defun bare-id! (val &key (return-pos 0))
  (assert (typep val 'number))
  (make-instance 'bare-flow-id :val val :return-pos return-pos))

(defmethod print-object ((o flow-identifier) stream)
  (let* ((ids (mapcar λ(slot-value _ 'val) (listify (ids o))))
	 (ids (if (> (length ids) 6)
		  (append (subseq ids 0 6) '(:etc))
		  ids)))
    (format stream "#<FLOW-ID ~{~s~^ ~}>" ids)))

(let ((gl-flow-id 0))
  (defun %gen-flow-gl-id () (bare-id! (decf gl-flow-id))))

;;----------------------------------------------------------------------

(defvar root-flow-gen-func
  (lambda ()
    (error "Trying to generate flow-id outside of a flow-id-scope")))

(defvar flow-gen-func root-flow-gen-func)

(defun %make-flow-id-source-func (from)
  (let ((%flow-id (typecase from
		     (function (funcall from :dump))
		     (integer from)
		     (otherwise (error "invalid 'from'")))))
    (lambda (&optional x)
      (if (eq x :dump)
	  %flow-id
	  (bare-id! (incf %flow-id))))))

(defstruct flow-id-checkpoint func)

(defmethod print-object ((obj flow-id-checkpoint) stream)
  (format stream "#<flow-id-checkpoint ~s>"
	  (funcall (flow-id-checkpoint-func obj) :dump)))

;;----------------------------------------------------------------------
;; scoping

(defmacro flow-id-scope (&body body)
  `(let ((flow-gen-func
	  (%make-flow-id-source-func -1)))
     ,@body))

(defun checkpoint-flow-ids ()
  (prog1 (make-flow-id-checkpoint :func flow-gen-func)
    (setf flow-gen-func (%make-flow-id-source-func flow-gen-func))))

(defun reset-flow-ids-to-checkpoint (checkpoint)
  (setf flow-gen-func (%make-flow-id-source-func
			(flow-id-checkpoint-func checkpoint)))
  t)

;;----------------------------------------------------------------------
;; construction

(defun m-flow-id! (flow-ids)
  (assert (and (listp flow-ids)
	       (every #'flow-id-p flow-ids)))
  (make-instance 'multi-return-flow-id
		 :m-value-ids flow-ids))

(defun flow-id! (&rest ids)
  (let ((ids (remove nil ids)))
    (labels ((key (_) (slot-value _ 'val)))
      (if (null ids)
	  (make-instance 'flow-identifier :ids (list (funcall flow-gen-func)))
	  (make-instance 'flow-identifier
			 :ids (sort (copy-list (remove-duplicates
						(mapcat #'ids ids)
						:key #'key))
				    #'< :key #'key))))))

(defun flow-id+meta! (&key return-pos)
  (let ((r (flow-id!)))
    (setf (slot-value (first (listify (ids r))) 'return-pos)
	  return-pos)
    r))

(defun %gl-flow-id! ()
  (make-instance 'flow-identifier :ids (list (%gen-flow-gl-id))))

(defun type-doesnt-need-flow-id (type)
  (or (typep type 'v-error)
      (typep type 'v-void)
      (typep type 'v-none)
      (eq type 'v-void)
      (eq type 'v-none)
      (eq type :void)
      (eq type :none)))


;;----------------------------------------------------------------------
;; inspection

(defun id~= (id-a id-b)
  (assert (or (typep id-a 'flow-identifier) (null id-a)))
  (assert (or (typep id-b 'flow-identifier) (null id-b)))
  (unless (or (null id-a) (null id-b))
    (not (null (intersection (listify (ids id-a)) (listify (ids id-b))
			     :key λ(slot-value _ 'val))))))

(defun id= (id-a id-b)
  (assert (or (typep id-a 'flow-identifier) (null id-a)))
  (assert (or (typep id-b 'flow-identifier) (null id-b)))
  (unless (or (null id-a) (null id-b))
    (equal (sort (copy-list (raw-ids id-a)) #'<)
	   (sort (copy-list (raw-ids id-b)) #'<))))

(defun assert-flow-id-singularity (flow-id)
  (assert (or (null flow-id)
	      (not (listp flow-id)))))
