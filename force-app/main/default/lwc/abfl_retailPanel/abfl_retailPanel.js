import { LightningElement, api, wire } from 'lwc';
import Modal from 'c/abfl_modal';
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ["Asset.Source_System__c"];

const itemLeftList = [
    {
        label: 'Loan Details',
        name: 'RTL_RealTime_LoanDetails'
    },
    {
        label: 'Basic Customer Info',
        name: 'RTL_RealTime_BasicCustInfo'
    }
];
const itemRightList = [
    {
        label: 'GCC Property Details ',
        name: 'RTL_RealTIme_GCCPropertyDetails'
    },
    {
        label: 'Loan MIS Snapshot',
        name: 'RTL_RealTime_LoanMIS'
    },
    {
        label: 'Installment Payment Details',
        name: 'RTL_RealTime_InstallPmntDtls'
    }
];

export default class Abfl_retailPanel extends LightningElement {
    @api recordId;
    apiName = '';
    navItemLeftList = itemLeftList;
    navItemRightList = itemRightList;
    selectedItem;

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    assetRecord;

    async showModal() {
        console.log('***handle click:');
        this.selectedItem = null;
        const result = await Modal.open({
            // `label` is not included here in this example.
            // it is set on lightning-modal-header instead
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
            templateId: this.apiName,
            assetId: this.recordId
        });
        // if modal closed with X button, promise returns result = 'undefined'
        // if modal closed with OK button, promise returns result = 'okay'
        console.log(result);
    }

    get isSourceSystemFINNRTL() {
        return this.assetRecord?.data?.fields?.Source_System__c?.value == 'FINNRTL' ? true : false;
    }
    get isSourceSystemA3S() {
        return this.assetRecord?.data?.fields?.Source_System__c?.value == 'A3S' ? true : false;
    }

    handleSelect(event) {
        console.log('in handleSelect');
        const selectedName = event.detail.name;
        this.apiName = selectedName;
        this.selectedItem = selectedName;

        let navItemList = itemLeftList.concat(itemRightList);
        let isOptionSelected = navItemList.some(item => item.name === this.selectedItem);

        console.log('selected API: ' + this.apiName);
        if (isOptionSelected) {
            this.showModal();
        }
    }
}