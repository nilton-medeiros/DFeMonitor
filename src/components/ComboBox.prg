#include "hmg.ch"
#include "hbclass.ch"

CLASS TComboBox

			VAR form READONLY
			VAR combo READONLY
			VAR cargo INIT {}

			METHOD NEW( cForm, comboBox, clear )
			METHOD AddItem( cDisplay, xCargo )
			METHOD getCargo( cHash )
			METHOD setCargo( cHash )
			METHOD setByID( nId ) SETGET
			METHOD setValue( nValue ) SETGET
			METHOD getValue() SETGET
			METHOD getDisplay() SETGET
			METHOD Clear() SETGET
			METHOD DeleteAllItems() INLINE ::Clear()
			METHOD Count() SETGET
			METHOD setEnabled( isEnable ) SETGET

END CLASS

METHOD NEW( cForm, comboBox, clear ) CLASS TComboBox
			DEFAULT clear := true
			::form := cForm
			::combo := comboBox
			if clear
				::Clear()
			endif
RETURN SELF

METHOD AddItem( cDisplay, xCargo ) CLASS TComboBox
			DoMethod( ::form, ::combo, "AddItem", cDisplay )
			AAdd( ::cargo, xCargo )
RETURN NIL

METHOD getCargo( cHash ) CLASS TComboBox
			LOCAL xCargo := ::cargo[ ::getValue() ]

			IF ValType( cHash ) == "C" .AND. ValType( xCargo ) == "H"
				RETURN xCargo[ cHash ]
			ENDIF

RETURN xCargo

METHOD setCargo( cHash ) CLASS TComboBox
			::cargo[ ::getValue() ] := cHash
RETURN NIL

METHOD setValue( nValue ) CLASS TComboBox
			DEFAULT nValue := 0
			SetProperty( ::form, ::combo, "Value", nValue )
RETURN NIL

METHOD getValue() CLASS TComboBox
RETURN GetProperty( ::form, ::combo, "Value" )

METHOD getDisplay() CLASS TComboBox
RETURN AllTrim( GetProperty( ::form, ::combo, "DisplayValue" ) )

METHOD setByID( nId ) CLASS TComboBox
			::setValue( HB_ASCan( ::cargo, {|xVal| IF( ValType(xVal) == "H", xVal['id'], xVal ) == nId} ) )
RETURN NIL

METHOD Clear() CLASS TComboBox
			DoMethod( ::form, ::combo, "DeleteAllItems" )
			::cargo := {}
RETURN NIL

METHOD Count() CLASS TComboBox
RETURN GetProperty( ::form, ::combo, "ItemCount" )

METHOD setEnabled( isEnable ) CLASS TComboBox
			DEFAULT isEnable := .T.
			SetProperty( ::form, ::combo, "Enabled", isEnable )
RETURN NIL