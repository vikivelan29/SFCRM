import getDynamicScreen from '@salesforce/apex/ABFL_RetailController.getDynamicScreen';
export function invokeCore(apiId, assetRecId){
	return getDynamicScreen({apiName: apiId, assetId: assetRecId}) 
	.then((result)=>{
		let screenjson;
		let title;
		let payload;
		title = result.title;
		screenjson = JSON.parse(JSON.stringify(result.secWrap));
		payload = JSON.parse(result.payload);
		console.log('***payload:'+payload);
		
		if(screenjson){
			screenjson.forEach(element => {
				console.log('***ele:'+JSON.stringify(element));
				for(let i=0; i<element.fieldsLeft.length;i++){
					for(let key in element.fieldsLeft[i]){
						console.log('***payload[fieldsLeft[i][key]:1-'+key);
						console.log('***payload[fieldsLeft[i][key]:0-'+element.fieldsLeft[i][key]);
						console.log('***payload[fieldsLeft[i][key]:0-chk:'+(element.fieldsLeft[i][key]+'').indexOf('.'));
						console.log('***payload[fieldsLeft[i][key]:2-'+payload[element.fieldsLeft[i][key]]);
						if(payload[element.fieldsLeft[i][key]] || (element.fieldsLeft[i][key]+'').indexOf('.')!=-1){
							console.log('in here');
		
							// Check if payload contains .
							console.log('***paths:'+JSON.stringify(element.fieldsLeft[i][key]));
							let value;
							if(element.fieldsLeft[i][key].includes('.')){
								console.log('***has path:');
								value = payload;
		
								let path = element.fieldsLeft[i][key].split('.');
								console.log('***paths:'+JSON.stringify(path));
								if(path.length>0){
									for (let i = 0; i < path.length; i++){
										console.log('in here-patu:'+path[i]);
										console.log('in here-value:'+JSON.stringify(value));
										value = value[path[i]];
										console.log('in here-patu:after:'+JSON.stringify(value));
									}
									console.log('final here-value:'+value);
								}
							}else{
								console.log('***no path:');
								value = payload[element.fieldsLeft[i][key]];
							}
							
							console.log('***value:'+value);
							// replace value from payload
							element.fieldsLeft[i][key]= value;
						}
					}
				}
	
				for(let i=0; i<element.fieldsRight.length;i++){
					for(let key in element.fieldsRight[i]){
						console.log('***payload[element.fieldsRight[i][key]:1-'+key);
						console.log('***payload[element.fieldsRight[i][key]:0-'+element.fieldsRight[i][key]);
						console.log('***payload[element.fieldsRight[i][key]:0-chk:'+(element.fieldsRight[i][key]+'').indexOf('.'));
						console.log('***payload[element.fieldsRight[i][key]:2-'+payload[element.fieldsRight[i][key]]);
						if(payload[element.fieldsRight[i][key]] || (element.fieldsRight[i][key]+'').indexOf('.')!=-1){
							console.log('in here');
		
							// Check if payload contains .
							console.log('***paths:'+JSON.stringify(element.fieldsRight[i][key]));
							let value;
							if(element.fieldsRight[i][key].includes('.')){
								console.log('***has path:');
								value = payload;
		
								let path = element.fieldsRight[i][key].split('.');
								console.log('***paths:'+JSON.stringify(path));
								if(path.length>0){
									for (let i = 0; i < path.length; i++){
										console.log('in here-patu:'+path[i]);
										console.log('in here-value:'+JSON.stringify(value));
										value = value[path[i]];
									}
									console.log('final here-value:'+value);
								}
							}else{
								console.log('***no path:');
								value = payload[element.fieldsRight[i][key]];
							}
							
							console.log('***value:'+value);
							// replace value from payload
							element.fieldsRight[i][key]= value;
						}
					}
				}

				console.log('***element.lTables: '+JSON.stringify(element.lTables));
				console.log('***element.lTables.length: '+element.lTables.length);
				for(let i=0; i<element.lTables.length;i++){
					for(let key in element.lTables[i]){
						console.log('***payload[element.lTables[i][key]:1-'+key);
						console.log('***payload[element.lTables[i][key]:0-'+element.lTables[i][key]);
						console.log('***payload[element.lTables[i][key]:0-chk:'+(element.lTables[i][key]+'').indexOf('.'));
						console.log('***payload[element.lTables[i][key]:2-'+payload[element.lTables[i][key]]);
						if((element.lTables[i][key]+'').indexOf('.')!=-1){
							console.log('in here');
		
							// Check if payload contains .
							console.log('***paths:'+JSON.stringify(element.lTables[i][key]));
							let value;
							if(element.lTables[i][key].includes('.')){
								console.log('***has path:');
								value = payload;
		
								let path = element.lTables[i][key].split('.');
								console.log('***paths:'+JSON.stringify(path));
								if(path.length>0){
									for (let i = 0; i < path.length; i++){
										console.log('in here-patu:'+path[i]);
										console.log('in here-value:'+JSON.stringify(value));
										value = value[path[i]];
									}
									console.log('final here-value:'+value);
								}
							}else{
								console.log('***no path:');
								value = payload[element.lTables[i][key]];
							}
							
							console.log('***table value:'+JSON.stringify(value));
							// replace value from payload
							element.lTables[i][key]= value;
						}
					}
				}
			});

			console.log('***final:'+JSON.stringify(screenjson));
		}
		console.log('check here:');
		return {
			'title':title,
			'screen':screenjson
		};
	})
	.catch((error) => {
		console.log('error:'+error);
	  });
}