import { LightningElement, wire, api, track } from 'lwc';
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Asset.AccountId';
export default class Abcl_CreateCaseFromAsset extends LightningElement {
    @api recordId;
    @track assetRecords;
    @track infoObject = {};
  //  @track currentSelRecord = {};
    fieldMappingForCase;
    fieldToBeStampedOnCase;
   // currentSelectedRec;
  withoutAsset = false;

  accountId;

  @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
  wiredAsset({ error, data }) {
      if (data) {
          this.accountId = data.fields.AccountId.value;
      } else if (error) {
        console.error('Accountid not found ',error );
    }
  }


@wire(fetchAssets, { accountRecordId: '$accountId'})
wiredAssets({ error, data }) {
    if (data) {
        this.assetRecords = data.assetRecords;
        this.fieldMappingForCase = data.fieldMappingForCase;
        this.setFieldMaapingOnCase();
    } 
    else if (error) {
        console.error('Error fetching  record', error);
    }
}

setFieldMaapingOnCase() {
    console.log('inside idasset ',this.recordId);
    this.fieldToBeStampedOnCase = { AssetId: this.recordId };
    console.log('fieldToBeStampedOnCase2 ',this.fieldToBeStampedOnCase);
   }
    resetBox(event){
        console.log('inside ccccc');
        this.assetId = '';
        //this.template.querySelector('lightning-datatable').selectedRows=[];
        this.showCreateCaseModal = false;
    }
}