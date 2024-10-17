import { LightningElement, wire, api, track } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { subscribe, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import MCRM_GymLocationSelectPartnerCode from '@salesforce/label/c.MCRM_GymLocationSelectPartnerCode';
import MCRM_RewardsSelectPartnerBenefitCode from '@salesforce/label/c.MCRM_RewardsSelectPartnerBenefitCode';
import MCRM_WireServiceTableMdtError from '@salesforce/label/c.MCRM_WireServiceTableMdtError';
import MCRM_InvokeApiError from '@salesforce/label/c.MCRM_InvokeApiError';
import MCRM_MissingDataError from '@salesforce/label/c.MCRM_MissingDataError';
import { customerAPIs } from 'c/mcrm_base_view_account';

export default class Mcrm_bv_container_extension extends LightningElement {

	label = {
		MCRM_GymLocationSelectPartnerCode,
		MCRM_RewardsSelectPartnerBenefitCode,
		MCRM_WireServiceTableMdtError,
		MCRM_InvokeApiError,
		MCRM_MissingDataError
	};

	// Configs
	@api recordId;
	@api dynTableExAPI;
	@api showPreview;
	pcvalue;
	bcvalue;
	options;
	partnerCodeOptions;
	benefitCodeOptions;
	pageSize;
	isError = false;
	errorMessage = "";

	// Internals
	showBaseView = false;
	columns;
	@track tableData;
	@track isShowInitialMessage = true;
	isLoading = false;

	get hasNoData() {
		if (this.tableData?.length > 0) {
			return 'slds-hide'
		} else {
			return '';
		}
	}
	get hasData() {
		if (this.tableData?.length > 0) {
			return '';
		} else {
			return 'slds-hide'
		}
	}

	get disablePartnerCodeButton() {
		return !(this.pcvalue);
	}

	get disableRewardsButton() {
		return !(this.pcvalue && this.bcvalue);
	}

	get noDataMessage(){
		if (this.isGymNameLocation){
			return this.label.MCRM_GymLocationSelectPartnerCode;
		} else if(this.isRewards){
			return this.label.MCRM_RewardsSelectPartnerBenefitCode;
		}
	}

	get isRewards(){
		return this.dynTableExAPI == 'MCRM_Rewards';
	}

	get isGymNameLocation(){
		return this.dynTableExAPI == 'MCRM_GymNameLocation';
	}

	get isActiveDay(){
		return this.dynTableExAPI == 'MCRM_ActiveDays';
	}


	@wire(MessageContext)
	messageContext;

	@wire(getTableMeta, { configName: '$dynTableExAPI' })
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

	connectedCallback() {
		this.subscribeToMessageChannel();
		if(this.isActiveDay){
			this.isShowInitialMessage = false;
		}

		this.showPreview=false;
	}

	subscribeToMessageChannel() {
		this.subscription = subscribe(
			this.messageContext,
			ViewEvent,
			(message) => this.handleMessage(message)
		);
	}

	handleMessage(message) {
		console.log('***handleMessage:'+JSON.stringify(message));
		this.isLoading = true;
		if (this.dynTableExAPI == 'MCRM_ActiveDays' && message.name == 'MCRM_ActiveDayURL') {
			console.log('***MCRM_ActiveDays:'+JSON.stringify(message));
			this.getActiveDays(message.payLoad);
		} else if (this.dynTableExAPI == 'MCRM_GymNameLocation' && message.name == 'MCRM_Gym_Voucher') {
			this.getGymNameLocation(message.payLoad);
		} else if (this.dynTableExAPI == 'MCRM_Rewards' && message.name == 'MCRM_Benefits'){
			this.getRewards(message.payLoad);
		}
		
		this.showBaseView = true;
		this.isLoading = false;
		this.showPreview=true;
	}
	
	getActiveDays(message) {
		console.log('***getActiveDays:'+JSON.stringify(message));
		let responseArray = [];
		this.isShowInitialMessage = false;
		message.responseMap.resultsList.scores.forEach(score => {
			score.activities.forEach(activity => {
				responseArray.push(
					{
						'activeDate': score.activeDate,
						'isScored': score.isScored == 'true' ? 'Yes' : 'No',
						'name': activity.name,
						'value': activity.value,
						'score': activity.score,
						'eventDate': activity.eventDate,
						'sourceName': activity.sourceName,
					}
				)
			});
		});
		this.tableData = responseArray;
	}

	getGymNameLocation(message) {
		// reset vars
		this.pcvalue = '';
		this.tableData = [];
		let partnerList = this.generateOptionsFromArray(message, 'partnerCd');
		this.options = partnerList;
	}

	getRewards(message) {
		// reset vars
		this.pcvalue = '';
		this.bcvalue = '';
		this.tableData = [];


		let responseArray = [];
		responseArray = message.responseMap.resultsList;
		let partnerList = this.generateOptionsFromArray(responseArray, 'partnerCd');
		let benefitCodeList = this.generateOptionsFromArray(responseArray, 'benefitCd');
		this.partnerCodeOptions = partnerList;
		this.benefitCodeOptions = benefitCodeList;
	}

	generateOptionsFromArray(responseArray, field){ //ADDED:03/10/24 - to generate options from array and remove duplicates
		let options = responseArray
		.filter(ele => {
			return ele[field];
		})
		.map(ele => {
			return { label: ele[field], value: ele[field] }
		});
		options = Array.from(new Set(options.map(ele=>JSON.stringify(ele)))).map(ele => JSON.parse(ele))
		return options;
	}

	handleChange(event) {
		if (event.target.name === "partners" || event.target.name === "partnerCode") {
			this.pcvalue = event.detail.value;
		} else if (event.target.name === "benefitCode") {
			this.bcvalue = event.detail.value;
		}
	}

	invokeAPI(parameters) {
		this.isLoading = true;
		this.isError = false;
		this.errorMessage = "";
		fetchAPIResponse({ recId: this.recordId, intName: this.dynTableExAPI, params: parameters })
			.then((result) => {
				this.isShowInitialMessage = false;
				let payLoad = result.payload ? JSON.parse(result.payload) : undefined;
				
				// Check validity of response
				if (result?.statusCode == 200 && payLoad) {
					this.tableData = customerAPIs(this.dynTableExAPI, payLoad);
				}
				this.isLoading = false;
				if (this.tableData && this.tableData.length > 0) {
					this.showBaseView = true;
					setTimeout(() => {
						this.template.querySelector("c-abc_base_tableview").refreshTable(responseArray);
					}, 200);

				} else {
					this.handleError(
						result,
						payLoad
					);
				}
			})
			.catch((error) => {
				this.isShowInitialMessage = false;
				this.isLoading = false;
				this.showError(this.label.MCRM_InvokeApiError);
			});
	}

	handleClick(event) {
		let params;
		if (event.target.name === "partnerCodeButton") {
			// invoke api
			params = {
				recordId: this.recordId,
				param1: this.pcvalue,
			};
		} else {
			// invoke api
			params = {
				param1: this.pcvalue,
				param2: this.bcvalue
			};
		}

		this.invokeAPI(params);
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

	showError(message) {
		this.showBaseView = false;
		this.isError = true;
		this.errorMessage = message;
    }

	get disablePreview(){
		return this.tableData?.length == 0;
	}

	get alignDiv(){
		return (this.isGymNameLocation ||this.isRewards)?"":"padding-top: 15px;";
	}

	handleChangeView(event) {
		this.template.querySelector("c-abc_base_tableview").changeViewFn();
    }
}