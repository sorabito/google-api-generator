
Object subclass: #GoogleApiCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiCreator commentStamp: 'RichardPrinz 3/4/2015 17:21' prior: 0!
Creates proxy classes for Google API's!

!GoogleApiCreator class methodsFor: 'as yet unclassified'!
createApi: apiDiscoveryObj inCategory: apiClassCategory
	| apiDefUrl apiDef apiDefObj apiName apiClassName apiAuth proxy url rootUrl des ver doc src |
	
	apiDefUrl := apiDiscoveryObj at: 'discoveryRestUrl' ifAbsent: [ 
		self error: 'discoveryRestUrl property missing' ].
	
	apiDef := ZnEasy get: apiDefUrl.
	( apiDef entity isKindOf: ZnStringEntity ) ifFalse: [
		self error: 'Invalid content received' ].
		
	apiDefObj := NeoJSONReader fromString: apiDef entity string.
	
"apiDefObj inspect."

	" check and extract api definition parameters "
	apiName := apiDefObj at: 'name' ifAbsent: [ self error: 'name property missing' ].
	url := apiDefObj at: 'baseUrl' ifAbsent: [ self error: 'baseUrl property missing' ].
	rootUrl := apiDefObj at: 'rootUrl' ifAbsent: [ self error: 'rootUrl property missing' ].
	des := apiDefObj at: 'description' ifAbsent: [ ].
	ver := apiDefObj at: 'version' ifAbsent: [ ].
	doc := apiDefObj at: 'documentationLink' ifAbsent: [ ].
	
	" create class comment "
	des ifNotNil: [ des := des, String cr, String cr ].
	des ifNil: [ des := '' ].
	des := des, 'Source: ', apiDefUrl, String cr.
	ver ifNotNil: [ des := des, 'Version: ', ver, String cr ].
	doc ifNotNil: [ des := des, 'Documentation: ', doc, String cr ].

	" create base class for this api "	
	apiClassName := 'Google', apiName capitalized, 'Api'.
	proxy := GoogleApiTools 
		createClassNamed: apiClassName 
		in: apiClassCategory
		subClassOf: GoogleApiProxy
		description: des.
		
	" root url method "
	src := 'rootPath', String cr, String tab, '^ ''', rootUrl, ''''.
	GoogleApiTools 
		createMethodIn: proxy 
		withSource: src.

	" base url method "
	src := 'basePath', String cr, String tab, '^ ''', url, ''''.
	GoogleApiTools 
		createMethodIn: proxy 
		withSource: src.

	" apiName method "
	src := 'apiName', String cr, String tab, '^ ''', apiName, ''''.
	GoogleApiTools 
		createMethodIn: proxy 
		withSource: src.

	" authentication scopes "
	src := 'scopes', String cr, 
		String tab, '^ OrderedCollection withAll: #(', String cr.
	apiAuth := apiDefObj at: 'auth' ifAbsent: [ {} ].
	apiAuth := apiAuth at: 'oauth2' ifAbsent: [ {} ].
	apiAuth := apiAuth at: 'scopes' ifAbsent: [ {} ].
	apiAuth keysDo: [ :k |
		src := src, String tab, String tab, '''', k asString, '''', String cr ].
	src := src, String tab, ')', String cr.
	GoogleApiTools 
		createMethodIn: proxy 
		withSource: src.	

	" create subclasses and methods for this api "
	GoogleApiCreator 
		createClassesFromResource: apiDefObj 
		underParentClass: proxy 
		withClassNamePrefix: apiClassName 
		inCategory: apiClassCategory 
		comment: ''.

! !

!GoogleApiCreator class methodsFor: 'as yet unclassified'!
createClassesFromResource: anApiDef underParentClass: aClass withClassNamePrefix: aClassNamePrefix inCategory: aClassCategory comment: aComment

	| res prefix |
	
	anApiDef ifNil: [ ^nil ].
	( anApiDef isKindOf: Dictionary )
		ifFalse: [ ^nil ].
	prefix := aClassNamePrefix asString.
	
	res := anApiDef at: 'resources' ifAbsent: [ ^nil ].
	res keysDo: [ :k || createdClassName createdClass api |
		api := res at: k ifAbsent: [ api := nil ].
		api ifNotNil: [					
			createdClassName := prefix, k capitalized.
			createdClass := GoogleApiTools 
				createClassNamed: createdClassName 
				in: aClassCategory
				subClassOf: aClass
				description: aComment.
									
			GoogleApiCreator 
				createMethodsFromApiDef: api 
				inClass: createdClass.
			
			createdClass ifNotNil: [
				GoogleApiCreator 
					createClassesFromResource: api
					underParentClass: createdClass 
					withClassNamePrefix: createdClassName 
					inCategory: aClassCategory 
					comment: aComment
				].
			]
		] 
	! !

!GoogleApiCreator class methodsFor: 'as yet unclassified'!
createMethodFromMethodDef: methodDef inClass: aClass named: methodName
	| sources |
	
	( methodDef isKindOf: Dictionary )
		ifFalse: [ ^nil ].

	sources := self 
		createSourceFromMethodDef: methodDef
		named: methodName.			
	sources ifNil: [ ^nil ].

	sources do: [ :source |
		source ifNotNil: [
			GoogleApiTools
				createMethodIn: aClass 
				withSource: source ] ].

	^ sources size.
! !

!GoogleApiCreator class methodsFor: 'as yet unclassified'!
createMethodsFromApiDef: apiDef inClass: aClass
	| methods cnt |
	
	( apiDef isKindOf: Dictionary )
		ifFalse: [ ^nil ].
		
	methods := apiDef at: 'methods' ifAbsent: [ ^nil ].	
		
	cnt := 0.
	UIManager default informUserDuring: [ :bar |
	bar label: 'generate methods in (', aClass name, ')'.
	
	methods keysAndValuesDo: [ :metName :metDef |
		cnt := cnt + 1.
		bar current: cnt.
		
		self 
			createMethodFromMethodDef: metDef 
			inClass: aClass
			named: metName ] ]
! !

!GoogleApiCreator class methodsFor: 'as yet unclassified'!
createSourceFromMethodDef: methodDef named: methodName
	| selector selector2 comment methodComment paramComment source source2 pathVar actionVar 
		paramDef isFirstParam isOptional isUpload uploadDef maxUpload acceptedMimes uploadProt 
		uploadProtSimple uploadPathSimple uploadProtResumable uploadPathResumable |
	
	( methodDef isKindOf: Dictionary )
		ifFalse: [ ^nil ].
	
	selector := methodName.
	methodComment := methodDef at: 'description' ifAbsent: [ ].	
	pathVar := ( methodDef at: 'path' ifAbsent: [ '' ] ) asString.
	actionVar := ( methodDef at: 'httpMethod' ifAbsent: [ 'GET' ] ) asString asUppercase.
	isUpload := ( methodDef at: 'supportsMediaUpload' ifAbsent: [ false ] ).
	uploadDef := ( methodDef at: 'mediaUpload' ifAbsent: [ Dictionary new ] ).
	maxUpload := ( uploadDef at: 'maxSize' ifAbsent: [ 0 ] ).
	acceptedMimes := ( uploadDef at: 'accept' ifAbsent: [ #('*/*') ] ).
	uploadProt := ( uploadDef at: 'protocols' ifAbsent: [ Dictionary new ] ).
	uploadProtSimple := ( uploadProt at: 'simple' ifAbsent: [ Dictionary new ] ).
	uploadPathSimple := ( uploadProtSimple at: 'path' ifAbsent: [ nil ] ).
	uploadProtResumable := ( uploadProt at: 'resumable' ifAbsent: [ Dictionary new ] ).
	uploadPathResumable := ( uploadProtResumable at: 'path' ifAbsent: [ nil ] ).
	
	" cycle through params to construct selector "
	isFirstParam := true.
	isOptional := false.

	paramDef := methodDef at: 'parameters' ifAbsent: [ ].	
	( paramDef isKindOf: Dictionary ) ifTrue: [
		
		( paramDef size > 0 ) ifTrue: [			
			paramComment := String tab, String tab, 
				'Parameters, * = required, optional parameters in optionsDict', 
				String cr, String cr ].
		
		paramDef keysAndValuesDo: [ :pName :pDef || pNameNorm pType pReq pDesc |
			
			" create a parameter description comment "
			pNameNorm := pName uncapitalized.
			pType := ( pDef at: 'type' ifAbsent: [ '' ] ) asString capitalized.
			pDesc := pDef at: 'description' ifAbsent: [ '' ].
			pReq := pDef at: 'required' ifAbsent: [ false ].
			pReq ifFalse: [ isOptional := true ].

			paramComment := paramComment, String tab, String tab, pNameNorm.
			( pType size > 0 ) ifTrue: [ 
				paramComment := paramComment, ' (', pType.
				pReq ifTrue: [ paramComment := paramComment, '*' ].
				paramComment := paramComment, ')' ].
			
			paramComment := paramComment, ': ', pDesc, String cr.

			pReq ifTrue: [
				( isFirstParam )
					ifTrue: [
						isFirstParam := false.
						selector := selector, ': ', pNameNorm, ' ' ]
					ifFalse: [
						selector := selector, pNameNorm, ': ', pNameNorm, ' ' ] 
			]
		]
	].

	" non required parameters are handled via a dictionary parameter "
	selector2 := selector.
	isOptional ifTrue: [
		( isFirstParam )
			ifTrue: [ selector := selector, ': optionsDict' ]
			ifFalse: [ selector := selector, 'options: optionsDict' ].
	].

	" build method comment "
	comment := ''.	
	methodComment ifNotNil: [
		comment := String tab, String tab, methodComment, String cr ].
	paramComment ifNotNil: [ 
		( comment size > 0 ) ifTrue: [
			comment := comment, String cr ].
		comment := comment, paramComment ].
	comment := comment copyWithRegex: '"' matchesReplacedWith: '""'.
	( comment size > 0 ) ifTrue: [
		comment := String tab, '"', String cr, comment, String tab, '"', String cr, String cr ].	
	
	" create code for main method "
	source := WriteStream on: ( String new ).
	isUpload
		ifTrue: [
			source
				<< ( selector, String cr );
				<< ( comment );
				<< ( String tab, '| action path values |', String cr, String cr );
				<< ( String tab, 'action := #', actionVar, '.', String cr );
				<< ( String tab, 'values := self argumentsFor: thisContext.', String cr );
				<< ( String tab, 'path := self rootPath, ( self ', 
					String cr, String tab, String tab,
						'replacePlaceholdersIn: ''', uploadPathSimple, ''' with: values ).', String cr, String cr );
				<< ( String tab, '^ self makeRequestTo: path usingMethod: action with: ' ) ]
		ifFalse: [
			source
				<< ( selector, String cr );
				<< ( comment );
				<< ( String tab, '| action path values |', String cr, String cr );
				<< ( String tab, 'action := #', actionVar, '.', String cr );
				<< ( String tab, 'values := self argumentsFor: thisContext.', String cr );
				<< ( String tab, 'path := self basePath, ( self ', 
					String cr, String tab, String tab,
						'replacePlaceholdersIn: ''', pathVar, ''' with: values ).', String cr, String cr );
				<< ( String tab, '^ self makeRequestTo: path usingMethod: action with: ' ) ].
		
	isOptional
		ifTrue: [ source << 'optionsDict.' ]
		ifFalse: [ source << 'nil.' ].
		
	" create convinience method "
	isOptional ifTrue: [
		source2 := WriteStream on: ( String new ).
		source2
			<< ( selector2, String cr, String cr );
			<< ( String tab, '^ self ', selector2 ).
			
		( isFirstParam )
			ifFalse: [ source2 << 'options' ].
			
		source2 << ( ': ( Dictionary new )', String cr ).
	].

	source := source contents.
	source2 
		ifNotNil: [ source2 := source2 contents ]
		ifNil: [ source2 := nil ].
	
	^ { source. source2 }.
	
! !
