module Example.Async.Component where

import Prelude

import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect.Aff (Aff, Milliseconds(..))
import Effect.Console (logShow)
import Example.App.UI.Element as UI
import Example.App.Validation as V
import Formless as F
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

-- Output type

type BankUser =
  { name :: String
  , email :: V.Email
  , balance :: Int
  }

-- Form 

newtype Form r f = Form (r (FormRow f))
derive instance newtypeForm :: Newtype (Form r f) _

type FormRow f =
  ( name    :: f V.FieldError String String
  , email   :: f V.FieldError String V.Email
  , balance :: f V.FieldError String Int
  )

-- Page component

-- We'll modify Formless' messages to only raise the successful parsed result
data Action
  = HandleFormless BankUser

type ChildSlot = 
  ( formless :: F.Slot' Form )

component :: H.Component HH.HTML (Const Void) Unit Void Aff
component = H.mkComponent
  { initialState: const unit
  , render
  , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
  }
  where
  handleAction = case _ of 
    HandleFormless bankUser -> H.liftEffect $ logShow (bankUser :: BankUser)

  render _ =
    UI.section_
      [ UI.h1_ [ HH.text "Formless" ]
      , UI.h2_ [ HH.text "A form with debounced async fields." ]
      , UI.p_
          """
          If you have fields with expensive validation, you can debounce modifications to the field with the async versions of setValidate and modifyValidate query functions. The result type of the form field lets you know whether the field has not been validated, is currently validating, or has produced an error or result.
          """
      , HH.br_
      , HH.slot F._formless unit (F.component spec) input (Just <<< HandleFormless)
      ]

  -----
  -- Formless
  -----

  input = 
    { initialInputs: F.mkInputFields (F.FormProxy :: F.FormProxy Form) -- easily generate inputs 
    , validators: Form
        { name: V.minLength 5
        , email: V.emailFormat >>> V.emailIsUsed
        , balance: V.strIsInt >>> V.enoughMoney
        }
    }

  spec = F.defaultSpec 
    { render = renderForm
    , handleMessage = case _ of
        F.Submitted outputs -> H.raise (F.unwrapOutputFields outputs)
        _ -> pure unit
    }
    where
    renderForm { form } =
      UI.formContent_
        [ UI.input
            { label: "Name"
            , help: UI.resultToHelp "Write your name" $ F.getResult prx.name form
            , placeholder: "Frank Ocean"
            }
            [ HP.value $ F.getInput prx.name form
            , HE.onValueInput (Just <<< F.setValidate_ prx.name)
            ]
        , UI.input
            { label: "Email"
            , help: UI.resultToHelp "Provide your email address" $ F.getResult prx.email form
            , placeholder: "john@hamm.com"
            }
            [ HP.value $ F.getInput prx.email form
            , HE.onValueInput (Just <<< F.asyncSetValidate_ (Milliseconds 300.0) prx.email)
            ]
        , UI.input
            { label: "Donation"
            , help: UI.resultToHelp "How many dollas do you want to spend?" $ F.getResult prx.balance form
            , placeholder: "1000"
            }
            [ HP.value $ F.getInput prx.balance form
            , HE.onValueInput (Just <<< F.asyncSetValidate_ (Milliseconds 500.0) prx.balance)
            ]
        , UI.buttonPrimary
            [ HE.onClick \_ -> Just F.submit_ ]
            [ HH.text "Submit" ]
        ]

    prx = F.mkSProxies (F.FormProxy :: F.FormProxy Form)
