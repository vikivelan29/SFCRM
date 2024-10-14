import { LightningElement,api,wire,track } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { publish, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import { customerAPIs } from 'c/mcrm_base_view_account';
import { contractAPIs } from 'c/mcrm_base_view_asset';

export default class Wellness_api_view extends LightningElement {
	// Configs
	@api dynTableAPI;
	@api secName;
    @api fireApiOnLoad;
    @api isShowDate;
    @api isCollapsed;
    @api showRefresh;
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
            this.showError("Oops! We couldn't retrieve the table metadata right now. Please try refreshing the page to see if that resolves the issue.");
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
			if (this.tableData) {
				this.showBaseView = true;
				this.template.querySelector("c-abc_base_tableview").refreshTable(this.tableData); //mutate; refresh the table data 
				if(this.passPayload){
					// publish event
					publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI});
				}
			} else {
				let res = result.payload ? JSON.parse(result?.payload) : undefined;
				let error = res?.message || res?.error?.description || undefined;
				if(error) {
					this.showError(error);
				} else {
					this.showError("We're Sorry! It looks like we couldn't find the information you were looking for. This might be due to a temporary issue or missing data. Please try again later.");
				}
			}
		})
		.catch((error) => {
			// console.log('***error:'+JSON.stringify(error.body.message));
			this.isLoading = false;
			this.showError("An Error Occurred: We're experiencing an issue on our end. Please try again later. If the problem persists, please contact your administrator for assistance.");
		});
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
		if(this.isShowDate==false && this.fireApiOnLoad==true){
			this.invokeAPI();
		}
    }

	handleMenuSelect(event) {
		this.invokeAPI();
    }
}