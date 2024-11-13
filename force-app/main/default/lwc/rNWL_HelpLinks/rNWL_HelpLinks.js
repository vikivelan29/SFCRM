import { LightningElement, api, wire } from 'lwc';
import RNWL_Seller_Portal_Link from '@salesforce/label/c.RNWL_Seller_Portal_Link';
import RNWL_Product_Features from '@salesforce/label/c.RNWL_Product_Features';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PAYMENT_LINK from "@salesforce/schema/Opportunity.Payment_Link__c";

export default class RNWL_HelpLinks extends LightningElement {
    @api recordId;
    autoCalculationLink = '';
    label = {
        RNWL_Seller_Portal_Link,
        RNWL_Product_Features
    };

    @wire(getRecord, {recordId: "$recordId", fields: [PAYMENT_LINK]})
    oppRecord;

    get paymentLink() {
        return getFieldValue(this.oppRecord.data, PAYMENT_LINK);
    }
}