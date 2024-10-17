// This is the testUtil component
function customerAPIs(apiName, payload) {
	switch (apiName) {
		case 'MCRM_Gym_Voucher':
			return getGymVoucher(payload)
		case 'MCRM_GymNameLocation':
			return getGymLocation(payload)
		case 'MCRM_TotalActiveDays':
			return getTotalActiveDays(payload)
		case 'MCRM_ActiveDayURL':
			return getActiveDayURL(payload)
		case 'MCRM_Assessments_Online_Questionnaire':
			return getAssessmentsOnlineQuestionnaire(payload)
		case 'MCRM_Assessments_Active_Age':
			return getAssessmentsActiveAge(payload)
		case 'MCRM_Improve_My_Status':
			return getImproveMyStatus(payload)
		case 'MCRM_Lifestyle_Voucher':
			return getLifestyleVoucher(payload)
		case 'MCRM_Wallet_Transaction':
			return getWalletTransaction(payload)
		case 'MCRM_Devices':
			return getDevices(payload)
		case 'MCRM_Benefits':
			return getBenefits(payload)
		case 'MCRM_Rewards':
			return getRewards(payload)
		case 'MCRM_Fitness_Score_And_Activity_Details':
			return getFitness(payload)
		case 'y':
			// code block
			break;
		default:
			console.log('No API available');
			return undefined;
	}
}

const getGymVoucher = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	let flattenArray = [];
	payload.forEach(
		(item) => {
			flattenArray.push(flattenObj(item));
		});
	return flattenArray;
}

const getGymLocation = (payload) => {
	return (
		payload?.responseMap?.resultsList != null  ? 
		[payload.responseMap.resultsList] : 
		[] 
	);
}

const getTotalActiveDays = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	if(!payload || 
		!payload.responseMap || 
		!payload.responseMap.resultsList || 
		!Array.isArray(payload.responseMap.resultsList.assessmentDetails) || 
		payload.responseMap.resultsList.assessmentDetails.length === 0) {
		// Return an empty array if checks fail
		return [];
	}
	return payload.responseMap.resultsList.assessmentDetails;
}

const getActiveDayURL = (payload) => {
	return (
		payload?.responseMap?.resultsList != null  ? 
		[payload.responseMap.resultsList] : 
		[] 
	);
}

const getAssessmentsOnlineQuestionnaire = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return payload;
}
const getAssessmentsActiveAge = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	let responseArray = [];
	if(payload && payload != null){
		responseArray.push(payload);
	}
	return responseArray;
}
const getImproveMyStatus = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	return payload;
}
const getLifestyleVoucher = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	if (!payload || 
        !Array.isArray(payload.resultList) || 
        payload.resultList.length === 0) {
        // Return an empty array if checks fail
        return [];
    }
	return payload.resultList;
}

const getWalletTransaction = (payload) => {
	let responseArray = [];
	if(payload && payload != null){
		responseArray.push(payload);
	}
	return responseArray;
}

const getDevices = (payload) => {
	// Return the apps if valid, or an empty array if checks fail
    return (
        payload?.responseMap?.resultsList?.apps?.length ? 
        payload.responseMap.resultsList.apps : 
        []
    );
}
const getBenefits = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return (
		payload?.responseMap?.resultsList?.length  ? 
		payload.responseMap.resultsList : 
		[] 
	);
}
const getRewards = (payload) => {
	return (
		payload?.responseMap?.resultsList?.length  ? 
		payload.responseMap.resultsList : 
		[] 
	);
}
const getFitness = (payload) => {
	return (
		payload?.responseMap?.resultsList?.length  ? 
		payload.responseMap.resultsList : 
		[] 
	);
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

export { customerAPIs }