import { LightningElement,api,wire,track } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { publish, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import { customerAPIs } from 'c/mcrm_base_view_account';
import { contractAPIs } from 'c/mcrm_base_view_asset';
import MCRM_WireServiceTableMdtError from '@salesforce/label/c.MCRM_WireServiceTableMdtError';
import MCRM_InvokeApiError from '@salesforce/label/c.MCRM_InvokeApiError';
import MCRM_MissingDataError from '@salesforce/label/c.MCRM_MissingDataError';

export default class Wellness_api_view extends LightningElement {
	label = {
		MCRM_WireServiceTableMdtError,
		MCRM_InvokeApiError,
		MCRM_MissingDataError
	};
	// Configs
	@api dynTableAPI;
	@api secName;
    @api fireApiOnLoad;
    @api isShowDate;
    @api isCollapsed;
    @api showRefresh;
    @api showPreview;
    @api passPayload;
	
	// Context var
	@api recordId;
	@api objectApiName;
	@wire(MessageContext)
  	messageContext;

	// Internals
	startDate;
	endDate;
    isLoading = false;
	@track tableData;
	columns;
	showBaseView = false;
	activeSections=[];
	isError = false;
	errorMessage = "";
	pageSize; //No of records to be displayed on the table
	errorMessageSearch;
    displayErrorSearch = false;
    connectedCallback(){
        if(this.isShowDate==false && this.fireApiOnLoad==true && !this.isCollapsed){
            this.invokeAPI();
        }
		if(!this.isCollapsed){
			this.activeSections.push('activeSection')
		}
    }
	get refreshClass(){
		return (this.showPreview==true)?"slds-float_right mcrmButton mcrmRefresh":"slds-float_right mcrmButton";
	}

	/*
	renderedCallback(){
		if(this.isShowDate==false && this.fireApiOnLoad==true && !this.isCollapsed){
			let payLoad = {'showExtension': this.activeSections.length > 0 };
			publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI,'payLoadType':'showExtension'});
        }
	}
	*/

	@wire (getTableMeta, {configName:'$dynTableAPI'})
	tableMeta({ error, data }) {
        if (data) {
			this.pageSize = data[0].Asf_Dynamic_Datatable_Parent__r.Page_Size__c || 5;
            this.columns = [
				...data.map(col => ({
					label: col.MasterLabel,
					fieldName: col.Api_Name__c,
					type: col.Data_Type__c,
					cellAttributes: { alignment: 'left' }
				}))
			];
        } else if (error) {
            this.showError(this.label.MCRM_WireServiceTableMdtError);
        }
    }

    invokeAPI(){
        this.isLoading = true;
		this.isError = false;
		this.errorMessage = "";
        // invoke API
		const params = {
			startDate: this.startDate,
			endDate: this.endDate
		};
		fetchAPIResponse({ recId: this.recordId, intName:this.dynTableAPI , params : params})
		.then((result) => {
			let payLoad = result.payload ? JSON.parse(result.payload) : undefined;
			
			// Check validity of response
			if (result?.statusCode == 200 && payLoad) {
				// invoke helper
				if(this.objectApiName=='Account'){
					this.tableData = customerAPIs(this.dynTableAPI, payLoad);
				}else{
					this.tableData = contractAPIs(this.dynTableAPI, payLoad);
				}
			}
			this.isLoading = false;
			if (this.tableData && this.tableData.length > 0) {
				if(this.dynTableAPI == 'MCRM_Devices'){
					this.tableData.forEach(row => {
						row.synced = row.synced == '1' ? 'true' : 'false';
					});
				}
				this.showBaseView = true;
				this.template.querySelector("c-abc_base_tableview").refreshTable(this.tableData); //mutate; refresh the table data 
				if(this.passPayload){
					// publish event
					publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI});
				}
			} else {
				this.clear();
				this.handleError(
					result,
					payLoad
				);
			}
		})
		.catch((error) => {
			this.clear();
			this.isLoading = false;
			this.showError(this.label.MCRM_InvokeApiError);
		});
    }

	clear(){
		let payLoad = {};
		this.tableData=[];
		this.template.querySelector("c-abc_base_tableview").refreshTable(this.tableData); //mutate; refresh the table data 
		this.showBaseView=false;
		publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI,'payLoadType':'clear'});
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

	handleToggleSection(event) {
		
		let payLoad = {'showExtension': event.detail.openSections.length > 0 };
		publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI,'payLoadType':'showExtension'});

		if(this.isShowDate==false && this.fireApiOnLoad==true){
			this.invokeAPI();
		}
    }

	handleMenuSelect(event) {
		this.invokeAPI();
    }

	handleChangeView(event) {
		this.template.querySelector("c-abc_base_tableview").changeViewFn();
    }

	get renderBaseView(){
		return this.showBaseView==true?'':'slds-hide';
	}

	handleRefresh(){
		this.invokeAPI();
	}

	get disablePreview(){
		return this.tableData==undefined || this.tableData?.length == 0;
	}
}