import { LightningElement, wire, api, track } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { subscribe, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import GymLocationNotAvailable from '@salesforce/label/c.MCRM_GymNameLocation';
// import RewardsDataNotAvailable from '@salesforce/label/c.MCRM_RewardsDataNotAvailable';

export default class Mcrm_bv_container_extension extends LightningElement {

	label = {
		GymLocationNotAvailable,
		// RewardsDataNotAvailable
	};

	// Configs
	@api recordId;
	@api dynTableExAPI;
	pcvalue;
	bcvalue;
	options;
	partnerCodeOptions;
	benefitCodeOptions;
	pageSize;

	// Internals
	showBaseView = false;
	showPartner = false;
	showRewards = false;
	columns;
	@track tableData;
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
		if (this.showPartner){
			return this.label.GymLocationNotAvailable;
		} else {
			// return this.label.RewardsDataNotAvailable;
		}
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
			this.showToast('Error', 'Error fetching data.', 'Error');
		}
	}

	connectedCallback() {
		this.subscribeToMessageChannel();
	}

	subscribeToMessageChannel() {
		this.subscription = subscribe(
			this.messageContext,
			ViewEvent,
			(message) => this.handleMessage(message)
		);
	}

	handleMessage(message) {
		this.isLoading = true;
		if (this.dynTableExAPI == 'MCRM_ActiveDays' && message.name == 'MCRM_ActiveDayURL') {
			this.getActiveDays(message.payLoad);
		} else if (this.dynTableExAPI == 'MCRM_GymNameLocation' && message.name == 'MCRM_Gym_Voucher') {
			this.getGymNameLocation(message.payLoad);
		} else if (this.dynTableExAPI == 'MCRM_Rewards' && message.name == 'MCRM_Benefits'){
			this.getRewards(message.payLoad);
		}

		this.showBaseView = true;
		this.isLoading = false;
	}

	getActiveDays(message) {
		let responseArray = [];
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

		this.showPartner = true;
		let partnerList = this.generateOptionsFromArray(message, 'partnerCd');
		this.options = partnerList;
	}

	getRewards(message) {
		// reset vars
		this.pcvalue = '';
		this.bcvalue = '';
		this.tableData = [];


		this.showRewards = true;
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
		fetchAPIResponse({ recId: this.recordId, intName: this.dynTableExAPI, params: parameters })
			.then((result) => {
				let payLoad = JSON.parse(result.payload);

				// Check validity of response
				if (result?.statusCode == 200 && payLoad) {
					let responseArray = [];

					if(!Array.isArray(payLoad.responseMap.resultsList)){
						responseArray.push(payLoad.responseMap.resultsList);
					}  else {
						responseArray = payLoad.responseMap.resultsList;
					}
					this.template.querySelector("c-abc_base_tableview").refreshTable(responseArray);
					this.tableData = JSON.parse(JSON.stringify(responseArray));

				} else {
					let res = JSON.parse(result?.payload);
					if (res?.error?.description) {
						this.showToast("Error", res.error.description, 'error');
					} else {
						this.showToast("Error", "There seems to be an error child", 'error');
					}
				}
			})
			.catch((error) => {
				this.showToast("Error", "Admin: There seems to be an error", 'error');
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
}