import getDynamicScreen from '@salesforce/apex/ABFL_RetailController.getDynamicScreen';
export function invokeCore(apiId, assetRecId) {
	return getDynamicScreen({ apiName: apiId, assetId: assetRecId })
		.then((result) => {
			let statusCode;
			let screenjson;
			let title;
			let payload;

			title = result.title;
			statusCode = result.statusCode;
			screenjson = JSON.parse(JSON.stringify(result.secWrap));
			if (result.statusCode == 200 && result.payload) {
				if(apiId == 'RTL_RealTime_LoanDetails' && JSON.parse(result.payload)?.Root?.ResponseGetLoanDetails?.DataArea?.LoanDetails?.Response?.Summary_Data) {
					payload = JSON.parse(result.payload);
				} else if(apiId == 'RTL_RealTime_BasicCustInfo' && JSON.parse(result.payload)?.ResponseGetBasicCustomerInfo?.DataArea?.BasicCustomerInfo?.Response?.Basic_Customer_Info){
					payload = JSON.parse(result.payload);
				} else if(apiId == 'RTL_RealTIme_GCCPropertyDetails' && JSON.parse(result.payload)?.ResponseGetGCCPropertyDetails?.DataArea?.GCCPropertyDetails?.Response){
					payload = JSON.parse(result.payload);
				} else if(apiId == 'RTL_RealTime_LoanMIS' && JSON.parse(result.payload)?.ResponseGetLoanMISSnapshot?.DataArea?.LoanMISSnapshot?.Response){
					payload = JSON.parse(result.payload);
				} else if(apiId == 'RTL_RealTime_InstallPmntDtls' && JSON.parse(result.payload)?.ResponseGetInstallmentPaymentDetails?.DataArea?.InstallmentPaymentDetails?.Response?.repayment_detail?.rows){
					payload = JSON.parse(result.payload);
				} else if(apiId == 'RTL_RealTime_GetCRMDetails' && JSON.parse(result.payload)?.crmapis?.length > 0){
					payload = JSON.parse(result.payload);
				} else {
					console.log('error');
				}
			}
			console.log('***payload:' + payload);

			if (screenjson && payload) {
				screenjson.forEach(element => {
					for (let i = 0; i < element.fieldsLeft.length; i++) {
						for (let key in element.fieldsLeft[i]) {
							if (payload[element.fieldsLeft[i][key]] || (element.fieldsLeft[i][key] + '').indexOf('.') != -1) {
								// Check if payload contains .
								let value;
								if (element.fieldsLeft[i][key].includes('.')) {
									value = payload;

									let path = element.fieldsLeft[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];;
										}
									}
								} else {
									value = payload[element.fieldsLeft[i][key]];
								}
								// replace value from payload
								element.fieldsLeft[i][key] = value;
							}
						}
					}

					for (let i = 0; i < element.fieldsRight.length; i++) {
						for (let key in element.fieldsRight[i]) {
							if (payload[element.fieldsRight[i][key]] || (element.fieldsRight[i][key] + '').indexOf('.') != -1) {

								// Check if payload contains .
								let value;
								if (element.fieldsRight[i][key].includes('.')) {
									value = payload;

									let path = element.fieldsRight[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];
										}
									}
								} else {
									value = payload[element.fieldsRight[i][key]];
								}
								// replace value from payload
								element.fieldsRight[i][key] = value;
							}
						}
					}
					for (let i = 0; i < element.lTables.length; i++) {
						for (let key in element.lTables[i]) {
							if ((element.lTables[i][key] + '').indexOf('.') != -1) {
								// Check if payload contains .
								let value;
								if (element.lTables[i][key].includes('.')) {
									value = payload;

									let path = element.lTables[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];
										}
									}
								} else {
									value = payload[element.lTables[i][key]];
								}

								// replace value from payload
								element.lTables[i][key] = value;
							}
						}
					}
				});

				console.log('***final:' + JSON.stringify(screenjson));
				return {
					'statusCode': statusCode,
					'title': title,
					'screen': screenjson
				};
			} else {
				return {
					'statusCode': statusCode,
					'title': title
				};
			}
		})
		.catch((error) => {
			console.log('error:' + error);
		});
}