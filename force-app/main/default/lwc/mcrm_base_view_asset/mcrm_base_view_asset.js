// This is the testUtil component
function contractAPIs(apiName, payload) {
	switch(apiName) {
		case 'MCRM_PointsScoreTransactionDetails':
			return getPointsScoreTransactionDetails(payload);
		  break;
      case 'MCRM_RefundDetails':
			return getRefundDetails(payload);
		  break;
      case 'MCRM_BillingDetails':
			return getBillingDetails(payload);
		  break;
		case 'y':
		  // code block
		  break;
		default:
		  console.log('No API available');
	  }
}

const getPointsScoreTransactionDetails = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	//console.log('***Helper>activeDays:'+JSON.stringify(flattenObj(payload)));
	// Iterate over flattening each object
	// let flattenArray=[];
	// payload.forEach(
	// 	(item) => {
	// 		flattenArray.push(flattenObj(item));
	// 	});
	//console.log('***Helper>activeDays2:'+JSON.stringify(flattenArray));
	return payload.responseMap.resultsList;
}
const getRefundDetails = (payload) => {
	
	return payload;
}
const getBillingDetails = (payload) => {
	
	return payload;
}
const flattenObj = (ob) => {
 
    // The object which contains the
    // final result
    let result = {};
 
    // loop through the object "ob"
    for (const i in ob) {
 
        // We check the type of the i using
        // typeof() function and recursively
        // call the function again
        if ((typeof ob[i]) === 'object' && !Array.isArray(ob[i])) {
            const temp = flattenObj(ob[i]);
            for (const j in temp) {
 
                // Store temp in result
                result[i + '.' + j] = temp[j];
            }
        }
 
        // Else store ob[i] in result directly
        else {
            result[i] = ob[i];
        }
    }
    return result;
};

export { contractAPIs }