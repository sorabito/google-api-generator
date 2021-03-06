actions
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
			GaGoogleApiTools
				createMethodIn: aClass 
				withSource: source ] ].

	^ sources size.
