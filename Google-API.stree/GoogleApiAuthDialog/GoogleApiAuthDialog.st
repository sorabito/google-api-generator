
Object subclass: #GoogleApiAuthDialog
	instanceVariableNames: 'authUrl window code'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiAuthDialog commentStamp: 'RichardPrinz 3/4/2015 17:04' prior: 0!
Opens a Diallog to enter Google API authentication credentials!

!GoogleApiAuthDialog methodsFor: 'accessing'!
authUrl
	^ authUrl! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
authUrl: anObject
	authUrl := anObject! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnCancelClick
	code := nil.
	window delete

	! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnCancelLabel
	^ 'Cancel'
	! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnCopyClick
	authUrl ifNotNil: [
		Clipboard default clipboardText: authUrl ].! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnCopyLabel
	^ 'Copy URL'! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnOkClick
	window delete! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
btnOkLabel
	^ 'OK'
	! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
code
	^ code! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
code: anObject
	code := anObject! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
infoText
	^ (
			( Text withAll: 'Use your browser to go to this URL:', String cr, String cr ) , 
			( Text string: 'http://www.google.at' 
				attribute: ( TextURL new url: 'http://philippeback.eu' ) ),
			( Text withAll: String cr, String cr, 'and enter the code here:' )
		).! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
initialExtent
	^ 500@260! !

!GoogleApiAuthDialog class methodsFor: 'as yet unclassified'!
open: anUrl
	Smalltalk garbageCollect.
	^ self new
		authUrl: anUrl;
		openAsMorph
! !

!GoogleApiAuthDialog methodsFor: 'accessing'!
openAsMorph 
	| m |
	
	window := (SystemWindow labelled: 'Google API authentication')
				model: self.
				
	window
		addMorph: ( m := LabelMorph new 
			contents: 'Browse to the following authentication URL:' )
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@0 corner: 0@20)).

	" auth url browser notice "
	window
		addMorph: ( m := PluggableTextMorph
			on: self
			text: #authUrl
			accept: nil
			readSelection: nil
			menu: nil)
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@20 corner: 0@120)).
		m disable.
		
	window
		addMorph: ( m := LabelMorph new 
			contents: 'Enter authentication code here:' )
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@130 corner: 0@150)).
	
	" code text field "
	window
		addMorph: ( m := PluggableTextMorph
			on: self
			text: #code
			accept: #code:
			readSelection: nil
			menu: nil)
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@150 corner: 0@180)).
	m autoAccept: true.
	m acceptOnCR: true.			

	" copy button "
	window
		addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnCopyClick
				label: #btnCopyLabel)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 0.33@0)
				offsets: (0@190 corner: 0@220)).

	" Cancel Button "
	window
		addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnOkClick
				label: #btnOkLabel)
			fullFrame: (LayoutFrame 
				fractions: (0.33@0 corner: 0.66@0)
				offsets: (0@190 corner: 0@220)).

	" OK button "
	window
		addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnCancelClick
				label: #btnCancelLabel)
			fullFrame: (LayoutFrame 
				fractions: (0.66@0 corner: 1@0)
				offsets: (0@190 corner: 0@220)).
	
	window openModal.
	
	^ code
! !
