baseline
baseline: spec
	<baseline>
	
	spec for: #common do: [
		spec
			package: 'Google-API'.
			
		spec
			group: 'default' with: #('Core');
			group: 'Core' with: #('Google-API') ].