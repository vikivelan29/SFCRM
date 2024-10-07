// This is the testUtil component
function customerAPIs(apiName, payload) {
	switch (apiName) {
		case 'MCRM_Gym_Voucher':
			return getGymVoucher(payload)
			break;
		case 'MCRM_GymNameLocation':
			return getGymLocation(payload)
			break;
		case 'MCRM_TotalActiveDays':
			return getTotalActiveDays(payload)
			break;
		case 'MCRM_ActiveDayURL':
			return getActiveDayURL(payload)
			break;
		case 'MCRM_Assessments_Online_Questionnaire':
			return getAssessmentsOnlineQuestionnaire(payload)
			break;
		case 'MCRM_Assessments_Active_Age':
			return getAssessmentsActiveAge(payload)
			break;
		case 'MCRM_Improve_My_Status':
			return getImproveMyStatus(payload)
			break;
		case 'MCRM_Lifestyle_Voucher':
			return getLifestyleVoucher(payload)
			break;
		case 'MCRM_Wallet_Transaction':
			return getWalletTransaction(payload)
			break;
		case 'MCRM_Devices':
			return getDevices(payload)
			break;
		case 'MCRM_Benefits':
			return getBenefits(payload)
			break;
		case 'MCRM_Rewards':
			return getRewards(payload)
			break;
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

const getTotalActiveDays = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	return payload.responseMap.resultsList.assessmentDetails;
}

const getActiveDayURL = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	let responseArray = [];
	responseArray.push(payload.responseMap.resultsList);
	return responseArray;
}


const getAssessmentsOnlineQuestionnaire = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return [payload];
}
const getAssessmentsActiveAge = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	return [payload];
}
const getImproveMyStatus = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	return payload;
}
const getLifestyleVoucher = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object
	return payload.resultList;
}

const getWalletTransaction = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return [payload];
}

const getDevices = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return payload.responseMap.resultsList.apps;
}
const getBenefits = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	// Iterate over flattening each object

	return payload.responseMap.resultsList;
}
const getRewards = (payload) => {
	// Columns should be mapped as per dynamic table configuration
	return payload.responseMap.resultsList;
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