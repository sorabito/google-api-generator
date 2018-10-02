
ComposableMorph subclass: #GoogleApiBrowser
	instanceVariableNames: 'discoverUrl apiListIndex selectedApi apiList apiNameList keyEventsDict categoryListIndex selectedCategory window'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiBrowser commentStamp: 'RichardPrinz 3/4/2015 17:05' prior: 0!
Opens a window allowing the user to discover all available Google services and to create proxy classes for a selected service API in a given package.!

!GoogleApiBrowser methodsFor: 'accesing'!
apiList
	^ apiList! !

!GoogleApiBrowser methodsFor: 'accesing'!
apiListIndex
	^ apiListIndex! !

!GoogleApiBrowser methodsFor: 'accesing'!
apiListIndex: index 
	apiListIndex := index.
	selectedApi := apiList
				at: index
				ifAbsent: [].
	self changed: #apiListIndex.
	self changed: #selectedApiDescription.! !

!GoogleApiBrowser methodsFor: 'accesing'!
apiNameList
	^ apiNameList! !

!GoogleApiBrowser methodsFor: 'event handling'!
btnCancelClick
	window delete! !

!GoogleApiBrowser methodsFor: 'user interface'!
btnCancelLabel
	^ 'Cancel'! !

!GoogleApiBrowser methodsFor: 'event handling'!
btnDiscoverClick
	self updateApiList.! !

!GoogleApiBrowser methodsFor: 'user interface'!
btnDiscoverLabel
	^ 'Discover URL:'! !

!GoogleApiBrowser methodsFor: 'event handling'!
btnGenerateClick
	| apiDiscoverObj apiName category |

	category := ''.
	selectedCategory ifNotNil: [
		category := selectedCategory asString ].
	( category size < 1 ) ifTrue: [ 
		self abort: 'You must provide either an existing or a new category', String cr,
		'where the proxy classes should be generated' title: 'Unable to generate API'.
		^ nil ].
	
	( apiListIndex < 1) ifTrue: [ 
		self abort: 'You must select an API definition' title: 'Unable to generate API'.
		^ nil ].

	apiDiscoverObj := apiList at: apiListIndex ifAbsent: [ 
		self abort: 'Internal error. Selected API not found.' title: 'Unable to generate API'.
		^ nil ].

"apiDiscoverObj inspect."


	"apiName := apiDiscoverObj at: 'name' ifAbsent: [ 'unknown' ]."
	apiName := apiNameList at: apiListIndex ifAbsent: [ 'unknown' ].
	
	( self questionWithoutCancel: 
			'Generate Google API (', apiName, ')', String cr,
			'proxy classes in category (', category, ')' 
		title: 'Are you sure' ) ifTrue: [ 
			GoogleApiCreator createApi: apiDiscoverObj inCategory: category ].
	! !

!GoogleApiBrowser methodsFor: 'user interface'!
btnGenerateLabel
	^ 'Generate'! !

!GoogleApiBrowser methodsFor: 'accesing'!
categoryListIndex
	^ categoryListIndex! !

!GoogleApiBrowser methodsFor: 'accesing'!
categoryListIndex: index 
	categoryListIndex := index.
	selectedCategory := self categoryNameList
				at: index
				ifAbsent: [ nil ].
	self changed: #categoryListIndex.
	self changed: #txtCategory.! !

!GoogleApiBrowser methodsFor: 'accesing'!
categoryNameList
	^ SystemOrganizer default categories sorted: [ :a :b | a < b ].! !

!GoogleApiBrowser methodsFor: 'as yet unclassified'!
initialize
	super initialize.
	
	apiListIndex := 0.
	categoryListIndex := 0.
	discoverUrl := 'https://www.googleapis.com/discovery/v1/apis'.
	
	self updateApiList; 
		apiListIndex: 1
		
! !

!GoogleApiBrowser class methodsFor: 'as yet unclassified'!
open
	Smalltalk garbageCollect.
	^ self new openAsMorph! !

!GoogleApiBrowser methodsFor: 'user interface'!
openAsMorph 
	| m |
	window := (SystemWindow labelled: 'Google API''s')
				model: self.

	"self deferredMessageRecipient: WorldState."

	" Discover URL & button "		
	window
		addMorph: ( m := self uiDiscoverUrl )
		fullFrame: (LayoutFrame
			fractions: (0@0 corner: 1@0)
			offsets: (0@0 corner: 0@30)).
	m color: window color.
	
	
	
	
	" API List "
	window 
		addMorph: ( m := self uiApiList )
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 0.5@0.45)
			offsets: (0@30 corner: 0@0)).
	m color: window color.

	" API Description "
	window 
		addMorph: ( m := self uiApiDescription )
		fullFrame: (LayoutFrame 
			fractions: (0.5@0 corner: 1@0.45)
			offsets: (0@30 corner: 0@0)).	
	m color: window color.

	" Categoriy List "		
	window 
		addMorph: ( m := self uiCategoryList )
		fullFrame: (LayoutFrame 
			fractions: (0.0@0.45 corner: 0.5@1)
			offsets: (0@30 corner: 0@30 negated)).	
	m color: window color.
	
	" Action Panel "
	window 
		addMorph: ( m := self uiActionPanel )
		fullFrame: (LayoutFrame 
			fractions: (0.5@0.45 corner: 1@1)
			offsets: (0@30 corner: 0@30 negated)).	
	m color: window color.

	window setUpdatablePanesFrom: #(#processNameList #stackNameList ).
	(window setLabel: 'Google API''s') openInWorld.

	^ window
	! !

!GoogleApiBrowser methodsFor: 'as yet unclassified'!
processListKey: aKey from: aView 
	self perform: (self keyEventsDict at: aKey ifAbsent: [ ^ self ])! !

!GoogleApiBrowser methodsFor: 'as yet unclassified'!
processListMenu: menu
	^menu addAllFromPragma: 'processBrowserProcessListMenu' target: self! !

!GoogleApiBrowser methodsFor: 'as yet unclassified'!
readApiDef: aUrl
	| apiDef apiDefObj |
	
	apiNameList := OrderedCollection new.
	apiList := {}.
		
	[ apiDef := ZnEasy get: aUrl.
		( apiDef entity isKindOf: ZnStringEntity ) ifFalse: [
			self error: 'Invalid content received' ] 
	] on: Error do: [ :ex || msg |
		msg := ( ex messageText = String empty )
				ifTrue: [ ex asString ]
				ifFalse: [ ex messageText ].
		self abort: msg title: 'Unable to discover API'.
		 ^ nil ].
	
	( ( apiDef statusLine code < 200 ) or: [ apiDef statusLine code > 299 ] ) ifTrue: [ 
		UIManager default 
			abort: aUrl asString, String cr, 'returns ', apiDef statusLine code asString, ' ',
			apiDef statusLine reason title: 'Unable to discover API'.
		^ nil ].
	
	apiDefObj := NeoJSONReader fromString: apiDef entity string.

	apiList := apiDefObj at: 'items' ifAbsent: [ Array new ].

	( apiList isKindOf: Array ) ifFalse: [ Array new ].
	apiNameList := OrderedCollection new.
	apiList do: [ :i || title ver pref |
		title := i at: 'title' ifAbsent: [ nil ].
		ver := i at: 'version' ifAbsent: [ nil ].
		pref := i at: 'preferred' ifAbsent: [ false ].
		title ifNotNil: [ | w |
			w := title.
			ver ifNotNil: [ w := w, ' (', ver, ')' ].
			pref ifTrue: [ w := w, '*' ].
			apiNameList add: w ] ].

! !

!GoogleApiBrowser methodsFor: 'accesing'!
selectedApiDescription
	| txt desc title ver pref docLnk |
	
	txt := ''.
	selectedApi ifNil: [ ^txt ].
	
	desc := selectedApi at: 'description' ifAbsent: [ '' ].
	docLnk := selectedApi at: 'documentationLink' ifAbsent: [ '' ].
	
	title := selectedApi at: 'title' ifAbsent: [].
	ver := selectedApi at: 'version' ifAbsent: [].
	pref := selectedApi at: 'preferred' ifAbsent: [ false ].
	title ifNotNil: [ | w |
		w := title.
		ver ifNotNil: [ w := w, ' (', ver, ')' ].
		pref ifTrue: [ w := w, '*' ].
		apiNameList add: w ].
	
	txt := title.
	( txt size > 0) ifTrue: [ txt := txt, String cr, String cr ].
	
	( desc size > 0 ) ifTrue: [
		txt := txt, desc ].
	( txt size > 0) ifTrue: [ txt := txt, String cr, String cr ].
	
	txt := txt, 'Preferred: ', ( pref ifTrue: [ 'Yes' ] ifFalse: [ 'No' ] ).
	( txt size > 0) ifTrue: [ txt := txt, String cr, String cr ].
	
	(docLnk size > 0 ) ifTrue: [
		txt := txt, 'Link: ', docLnk ].
	
	
	^ txt
	! !

!GoogleApiBrowser methodsFor: 'accesing'!
txtCategory
	^ selectedCategory
	! !

!GoogleApiBrowser methodsFor: 'accesing'!
txtCategory: aStringOrText
	| index |
	
	selectedCategory := aStringOrText asString trimBoth.
	selectedCategory = String empty ifTrue: [ selectedCategory := nil ].
	
	index := self categoryNameList indexOf: selectedCategory ifAbsent: [ 0 ]. 	
	categoryListIndex := index.
	self changed: #categoryListIndex "]."
! !

!GoogleApiBrowser methodsFor: 'accesing'!
txtDiscoverUrl
	^ discoverUrl.
	! !

!GoogleApiBrowser methodsFor: 'accesing'!
txtDiscoverUrl: aUrl
	discoverUrl := aUrl asString.
	! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiActionPanel
	| m |
	
	m := Morph new layoutPolicy: ProportionalLayout new.

	" Category label and txtbox "	
	m addMorph: (TextMorph new 
			contents: ' Actions')
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@7 corner: 100@30)).
			
	m addMorph: (self uiCategoryInput)
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@30 corner: 0@60)).
	
	" Generate and Cancel buttons "
	m addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnGenerateClick
				label: #btnGenerateLabel)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 0.5@0)
				offsets: (0@80 corner: 0@110)).
		
	m addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnCancelClick
				label: #btnCancelLabel)
			fullFrame: (LayoutFrame 
				fractions: (0.5@0 corner: 1@0)
				offsets: (0@80 corner: 0@110)).

	^ m
! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiApiDescription
	| m dm |
	
	m := Morph new layoutPolicy: ProportionalLayout new.
	
	m addMorph: (TextMorph new 
			contents: ' Description')
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@7 corner: 100@30)).
		
	m addMorph: (dm := PluggableTextMorph
			on: self
			text: #selectedApiDescription
			accept: nil
			readSelection: nil
			menu: nil)
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@1)
			offsets: (0@30 corner: 0@30)).
	dm disable.

	^ m
	! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiApiList
	| m |
	
	m := Morph new layoutPolicy: ProportionalLayout new.	
		
	m addMorph: (TextMorph new 
				contents: ' API''s')
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 1@0)
				offsets: (0@7 corner: 100@30)).
				
	m addMorph: ((PluggableListMorph
				on: self
				list: #apiNameList
				selected: #apiListIndex
				changeSelected: #apiListIndex:
				menu: #apiListMenu:
				keystroke: #apiListKey:from:)
				enableDragNDrop: false)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 1@1)
				offsets: (0@30 corner: 0@30)).
				
	^ m.
! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiCategoryInput
	| m dm |
	
	m := Morph new layoutPolicy: ProportionalLayout new.	
		
	"m addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnDiscoverClick
				label: #btnDiscoverLabel)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 0@0)
				offsets: (0@0 corner: 100@30))."
	m addMorph: (StringMorph new 
			contents: ' Category:')
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 0@0)
			offsets: (0@6 corner: 70@30)).
	m color: window color.
		
	m addMorph: (dm := PluggableTextMorph
				on: self
				text: #txtCategory
				accept: #txtCategory:
				readSelection: nil
				menu: nil)
			"frame: (0.0 @ 0.0 extent: 1 @ 0.1)."
			"fullFrame: (LayoutFrame offsets: (0@0 corner: 100@50))."
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 1@0)
				offsets: (70@0 corner: 0@30)).
	dm autoAccept: true.
	dm acceptOnCR: true.

	^ m
	! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiCategoryList
	| m |
	
	m := Morph new layoutPolicy: ProportionalLayout new.
	
	m addMorph: (TextMorph new 
			contents: ' Categories')
		fullFrame: (LayoutFrame 
			fractions: (0@0 corner: 1@0)
			offsets: (0@7 corner: 100@30)).

	m addMorph: ((PluggableListMorph
				on: self
				list: #categoryNameList
				selected: #categoryListIndex
				changeSelected: #categoryListIndex:
				menu: nil
				keystroke: nil)
				enableDragNDrop: false)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 1@1)
				offsets: (0@30 corner: 0@30)).

	^ m
! !

!GoogleApiBrowser methodsFor: 'user interface'!
uiDiscoverUrl
	| m dm |
	
	m := Morph new layoutPolicy: ProportionalLayout new.	
		
	m addMorph: (PluggableButtonMorph
				on: self 
				getState: nil
				action: #btnDiscoverClick
				label: #btnDiscoverLabel)
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 0@0)
				offsets: (0@0 corner: 100@30)).
		
	m addMorph: (dm := PluggableTextFieldMorph
				on: self
				text: #txtDiscoverUrl
				accept: #txtDiscoverUrl:
				readSelection: nil
				menu: nil)
			"frame: (0.0 @ 0.0 extent: 1 @ 0.1)."
			"fullFrame: (LayoutFrame offsets: (0@0 corner: 100@50))."
			fullFrame: (LayoutFrame 
				fractions: (0@0 corner: 1@0)
				offsets: (100@0 corner: 0@30)).
	dm autoAccept: true.
	dm acceptOnCR: true.
	
	^ m
	! !

!GoogleApiBrowser methodsFor: 'as yet unclassified'!
updateApiList
	| oldSelectedApi newIndex |

	oldSelectedApi := selectedApi.
	apiList := selectedApi := nil.

	self readApiDef: discoverUrl.
		
	newIndex := apiList
				indexOf: oldSelectedApi
				ifAbsent: [ ( apiList size > 0 )
					ifTrue: [ 1 ]
					ifFalse: [ 0 ] ].
				
	self changed: #apiNameList.
	self apiListIndex: newIndex
! !
