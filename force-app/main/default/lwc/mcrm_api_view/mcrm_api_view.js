import { LightningElement,api,track } from 'lwc';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { contractAPIs } from 'c/mcrm_base_view_asset';

export default class Wellness_api_view extends LightningElement {
    @api recordId;
	@api intAPIName;
    @api isShowDate = false;

	@api objectApiName;

    showSpinner = false;
	showBaseViewScreen = false;
	payloadInfo;
    responseMessage;
	responseArray = [];
    startDate;
    endDate;
    errorMessageSearch;
    displayErrorSearch = false;
	isError = false;
	errorMessage = "";

    get isDirectInvoke(){
        return !this.isShowDate;
    }

    connectedCallback(){
        if(this.isDirectInvoke){
            this.invokeAPI();
        }
    }

    invokeAPI(){
        this.showSpinner = true;
        this.isError = false;
		this.errorMessage = "";
        // invoke API
		const params = {
			startDate: this.startDate,
			endDate: this.endDate
		};
		fetchAPIResponse({ recId: this.recordId, intName:this.intAPIName , params : params})
		.then((result) => {
			let payLoad = JSON.parse(result.payload);
			let tableData = [];
			// Check validity of response
			if (result?.statusCode == 200 && payLoad) {
				this.payloadInfo = result;
				if(this.objectApiName=='Asset'){
					tableData = contractAPIs(this.intAPIName, payLoad);
				}
				// if(this.isShowDate){
                //     let pl = {rows:[]};
				//     pl.rows.push(payLoad.responseMap.resultsList);
				//     this.payloadInfo.payload=JSON.stringify(pl);
                // }
			}
			this.showSpinner = false;
			if (tableData && tableData.length > 0) {
				this.showBaseViewScreen = true;
			} else {
				this.handleError(
					result,
					payLoad
				);
			}

			setTimeout(() => {             
				this.template.querySelector('c-mcrm_base_view_screen').callFunction();
			}, 200);
		})
		.catch((error) => {
			this.showSpinner = false;
			this.showError("An Error Occurred: We're experiencing an issue on our end. Please try again later. If the problem persists, please contact your administrator for assistance.");
		});
    }

	handleError(result, payLoad ){
		let errorMessages = [];
		// let res = result.payload ? JSON.parse(result?.payload) : undefined;
		if (result.statusCode == 200) {
			// Success responses (200)

			if (payLoad && (Array.isArray(payLoad) && payLoad.length === 0) || 
			(typeof payLoad === 'object' && Object.keys(payLoad).length === 0)) {
				errorMessages.push(this.label.MCRM_MissingDataError);
			}else{
				// Check if responseMap is empty or resultsList is null
				if (!payLoad.responseMap ||
					Object.keys(payLoad.responseMap).length === 0 ||
					payLoad.responseMap.resultsList === null) {
					// Check for service messages
					if (payLoad.serviceMessages) {
						payLoad.serviceMessages.forEach(message => {
							if (message.businessDesc) {
								errorMessages.push(message.businessDesc);
							}
						});
					}
				}
			}
		}
		if(result.statusCode > 200 || errorMessages.length == 0){
			let error = payLoad?.message || payLoad?.error?.description || this.label.MCRM_MissingDataError;
			errorMessages.push(error);
		}
		if(errorMessages.length > 0){
			let error = errorMessages.join('. ');
			this.showError(error);
		}
	}

    handleSearchClick() {
		const allValid = [
            ...this.template.querySelectorAll('.inpFieldCheckValidity'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
			this.invokeAPI();
        }

    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.validateDates();
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.validateDates();
    }

	validateDates() {
		if (this.startDate && this.endDate) {
			const start = new Date(this.startDate);
			const end = new Date(this.endDate);
	
			if (end < start) {
				this.displayErrorSearch = true;
			} else {
				this.displayErrorSearch = false;
			}
		} else {
			this.displayErrorSearch = false; // Hide error if one of the dates is missing
		}
	}

    showError(message) {
		this.isError = true;
		this.errorMessage = message;
    }

	handleRefresh(){
		this.invokeAPI();
	}
}