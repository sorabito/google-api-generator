
Object subclass: #GoogleApiTools
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiTools commentStamp: 'RichardPrinz 3/4/2015 17:07' prior: 0!
Some misc. functions used for creating Google API proxy classes !

!GoogleApiTools class methodsFor: 'as yet unclassified'!
base64ContentsOfFileNamed: aString 
	| file base64Contents |
	
	file := FileStream readOnlyFileNamed: aString.
	base64Contents := ( Base64MimeConverter mimeEncode: file binary ) contents.
	file close.
	
	^ base64Contents! !

!GoogleApiTools class methodsFor: 'as yet unclassified'!
createClassNamed: aNameStringOrSymbol in: aCategoryString subClassOf: aClass description: aDescriptionString
	" create a GoogleApi class in the given category "
	
	| proxy desc cat cls |
	
	cat := aCategoryString.
	cat ifNil: [ cat := 'Google-API' ].
	cls := aClass.
	cls ifNil: [ cls := Object ].
	
	proxy := cls subclass: aNameStringOrSymbol asSymbol
		instanceVariableNames: ''
		classVariableNames: ''
		poolDictionaries: ''
		category: aCategoryString.
		
	desc := '*** automatically created by GoogleApiCreator ***', String cr.
	aDescriptionString ifNotNil: [ 
		desc := desc, String cr, aDescriptionString ].
	
	proxy classComment: desc.
	
	^ proxy
! !

!GoogleApiTools class methodsFor: 'as yet unclassified'!
createMethodIn: aClass withSource: source
	| selector |
	"| methodAndNode  method selector |"

	"methodAndNode := aClass 
							compile: source
							classified: nil
							notifying: nil
							trailer: aClass defaultMethodTrailer
							trailer: nil
							ifFail: [ ^nil ].
							
	selector := methodAndNode selector.
	method := methodAndNode method.
	
	aClass 
		addSelectorSilently: selector 
		withMethod: method.
	
	aClass 
		logMethodSource: source 
		forMethodWithNode: methodAndNode 
		inCategory: nil 
		withStamp: nil 
		notifying: nil."
	
	selector := aClass 
		compile: source
		classified: #generated
		withStamp: nil 
		notifying: nil
		logSource: true.
							
	^ selector

	
	" create instance variable "
	"varName := 'fld', ( fieldSymbol capitalized ).
	( entityClass instVarNames includes: varName ) ifFalse: [ 
		entityClass addInstVarNamed: varName ]."
	
	" create getter "
	"getterSelector := fieldSymbol.
	method := (entityClass compile: getterSelector, String cr,
								'^ ', varName
							classified: nil
							notifying: nil
							trailer: entityClass defaultMethodTrailer
							ifFail: [nil]) method.							
	entityClass addSelectorSilently: getterSelector withMethod: method."

	" create setter "
	"setterSelector := (fieldSymbol, ':') asSymbol.
	method := (entityClass compile: setterSelector, ' aValue', String cr,
								varName, ' := aValue'
							classified: nil
							notifying: nil
							trailer: entityClass defaultMethodTrailer
							ifFail: [nil]) method.	
	entityClass addSelectorSilently: setterSelector withMethod: method."

! !

!GoogleApiTools class methodsFor: 'as yet unclassified'!
replaceInvalidPathChars: aString
	| w |
	
	w := aString.
	w ifNotNil: [
		w := w copyWithRegex: '[:\\+\\*\\?\\''\\"\\.]' matchesReplacedWith: '_' ].
	
	^ w! !

!GoogleApiTools class methodsFor: 'as yet unclassified'!
replacePlaceholders: aTemplate with: aDictionary 
	| template params w reg |
	
	" 
	GoogleApiTools replacePlaceholders: 'I am a {param}' 
		with: { 'param' -> 'test' } asDictionary 
	"
	
	template := aTemplate.
	template ifNil: [ template := '' ]
			ifNotNil: [ template := template asString ].
	
	params := aDictionary.
	params ifNil: [ params := Dictionary new ].
	
	reg := '({([a-zA-Z0-9]+)})' asRegex.
	
	w := aTemplate 
			copyWithRegex: '{[a-zA-Z0-9]+}' 
			matchesTranslatedUsing: [ :placeholder || key value |
				reg matchesPrefix: placeholder.
				key := reg subexpression: 3.
				value := aDictionary at: key ifAbsent: [ reg subexpression: 2 ].
				value asString
			].
	^ w! !
