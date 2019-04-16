-- | This module exports helpers for working with Formless actions, which you
-- | will use in your render function to attach to appropriate fields. Prefer
-- | these over using data constructors from the Formless action type. You can
-- | also freely extend Formless with more actions of your own using `injAction`.
module Formless.Action where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, wrap)
import Data.Symbol (class IsSymbol, SProxy(..))
import Data.Time.Duration (Milliseconds)
import Data.Tuple (Tuple(..))
import Data.Variant (Variant, inj)
import Formless.Class.Initial (class Initial, initial)
import Formless.Transform.Record (WrapField, wrapInputFields, wrapInputFunctions)
import Formless.Types.Component (Action)
import Formless.Types.Form (InputField, InputFunction, U(..))
import Heterogeneous.Mapping as HM
import Prim.Row as Row

-- | Inject your own action into the Formless component so it can be used in HTML
injAction :: forall form act. act -> Action form act
injAction = inj (SProxy :: _ "userAction")

-- | Set the input value of a form field at the specified label
set_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => SProxy sym
  -> i
  -> Action form act
set_ sym i = 
  inj (SProxy :: _ "modify") (wrap (inj sym (wrap (const i))))

-- | Modify the input value of a form field at the specified label with the
-- | provided function.
modify_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => SProxy sym
  -> (i -> i)
  -> Action form act
modify_ sym f = 
  inj (SProxy :: _ "modify") (wrap (inj sym (wrap f)))

-- | A helper to create the correct `Validate` query for Formless, given
-- | a label
validate_
  :: forall form act sym us r e i o
   . IsSymbol sym
  => Newtype (form Variant U) (Variant us)
  => Row.Cons sym (U e i o) r us
  => SProxy sym
  -> Action form act
validate_ sym = 
  inj (SProxy :: _ "validate") (wrap (inj sym U))

-- | Set the input value of a form field at the specified label, also triggering
-- | validation to run on the field.
setValidate_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => SProxy sym
  -> i
  -> Action form act
setValidate_ sym i = 
  inj (SProxy :: _ "modifyValidate") (Tuple Nothing (wrap (inj sym (wrap (const i)))))

-- | Modify the input value of a form field at the specified label, also triggering
-- | validation to run on the field, with the provided function.
modifyValidate_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => SProxy sym
  -> (i -> i)
  -> Action form act
modifyValidate_ sym f = 
  inj (SProxy :: _ "modifyValidate") (Tuple Nothing (wrap (inj sym (wrap f))))

-- | Set the input value of a form field at the specified label, while debouncing
-- | validation so that it only runs after the specified amount of time has elapsed
-- | since the last modification. Useful when you need to avoid expensive validation
-- | but do not want to wait for a blur event to validate.
asyncSetValidate_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => Milliseconds
  -> SProxy sym
  -> i
  -> Action form act
asyncSetValidate_ ms sym i = 
  inj (SProxy :: _ "modifyValidate") (Tuple (Just ms) (wrap (inj sym (wrap (const i)))))

-- | Modify the input value of a form field at the specified label, while debouncing
-- | validation so that it only runs after the specified amount of time has elapsed
-- | since the last modification. Useful when you need to avoid expensive validation
-- | but do not want to wait for a blur event to validate.
asyncModifyValidate_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => Milliseconds
  -> SProxy sym
  -> (i -> i)
  -> Action form act
asyncModifyValidate_ ms s f = 
  inj (SProxy :: _ "modifyValidate") (Tuple (Just ms) (wrap (inj s (wrap f))))

-- | Reset the value of the specified form field to its default value
-- | according to the `Initial` type class.
reset_
  :: forall form act sym inputs r e i o
   . IsSymbol sym
  => Initial i
  => Newtype (form Variant InputFunction) (Variant inputs)
  => Row.Cons sym (InputFunction e i o) r inputs
  => SProxy sym
  -> Action form act
reset_ sym = 
  inj (SProxy :: _ "reset") (wrap (inj sym (wrap (const initial))))

-- | Provide a record of input fields to overwrite all current
-- | inputs. Unlike `loadForm`, this does not otherwise reset
-- | the form as if it were new. Similar to calling `set` on every
-- | field in the form. Does not run validation.
setAll_
  :: forall form act is is'
   . Newtype (form Record InputField) {| is' }
  => HM.HMap WrapField {| is } {| is' }
  => {| is } 
  -> Action form act
setAll_ is = 
  inj (SProxy :: _ "setAll") (Tuple (wrapInputFields is) false)

-- | Provide a record of input functions to modify all current
-- | inputs. Similar to calling `modify` on every field in the form.
-- | Does not run validation.
modifyAll_
  :: forall form act ifs' ifs
   . Newtype (form Record InputFunction) {| ifs' }
  => HM.HMap WrapField {| ifs } {| ifs' }
  => {| ifs }
  -> Action form act
modifyAll_ fs = 
  inj (SProxy :: _ "modifyAll") (Tuple (wrapInputFunctions fs) false)

-- | Validate all fields in the form, collecting errors
validateAll_ :: forall form act. Action form act
validateAll_ = 
  inj (SProxy :: _ "validateAll") unit

-- | Provide a record of inputs to overwrite all current inputs without
-- | resetting the form (as `loadForm` does), and then validate the
-- | entire new set of fields. Similar to calling `setValidate` on every
-- | field in the form.
setValidateAll_
  :: forall form act is' is
   . Newtype (form Record InputField) {| is' }
  => HM.HMap WrapField {| is } {| is' }
  => {| is }
  -> Action form act
setValidateAll_ is = 
  inj (SProxy :: _ "setAll") (Tuple (wrapInputFields is) true)

-- | Provide a record of input functions to modify all current
-- | inputs, and then validate all fields.  Similar to calling
-- | `modifyValidate` on every field in the form.
modifyValidateAll_
  :: forall form act ifs' ifs
   . Newtype (form Record InputFunction) {| ifs' }
  => HM.HMap WrapField {| ifs } {| ifs' }
  => {| ifs }
  -> Action form act
modifyValidateAll_ ifs = 
  inj (SProxy :: _ "modifyAll") (Tuple (wrapInputFunctions ifs) true)

-- | Reset all fields to their initial values, and reset the form
-- | to its initial pristine state, no touched fields.
resetAll_ :: forall form act. Action form act
resetAll_ = 
  inj (SProxy :: _ "resetAll") unit

-- | Submit the form, which will trigger a `Submitted` result if the
-- | form validates successfully.
submit_ :: forall form act. Action form act
submit_ = 
  inj (SProxy :: _ "submit") unit

-- | Load a form from a set of existing inputs. Useful for when you need to mount
-- | Formless, perform some other actions like request data from the server, and 
-- | then load an existing set of inputs. 
loadForm_ :: forall form act. form Record InputField -> Action form act
loadForm_ = inj (SProxy :: _ "loadForm")
