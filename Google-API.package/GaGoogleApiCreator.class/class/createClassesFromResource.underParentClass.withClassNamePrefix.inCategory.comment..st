actions
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
			createdClass := GaGoogleApiTools 
				createClassNamed: createdClassName 
				in: aClassCategory
				subClassOf: aClass
				description: aComment.
									
			GaGoogleApiCreator 
				createMethodsFromApiDef: api 
				inClass: createdClass.
			
			createdClass ifNotNil: [
				GaGoogleApiCreator 
					createClassesFromResource: api
					underParentClass: createdClass 
					withClassNamePrefix: createdClassName 
					inCategory: aClassCategory 
					comment: aComment
				].
			]
		] 
	