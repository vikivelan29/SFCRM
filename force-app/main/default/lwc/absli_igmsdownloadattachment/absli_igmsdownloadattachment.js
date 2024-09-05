import { LightningElement,api } from 'lwc';
import download from "@salesforce/apex/ABSLI_DownloadIGMSComplaintIntegration.downloadAttachment";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Absli_igmsdownloadattachment extends LightningElement {
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }
    
    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
       }
    }

    isExecuting = false;

    @api async invoke() {
      if (this.isExecuting) {
        return;
      }
      download({recId : this.recordId}).then((result) => {this.showToast('Success','The Download has been successfully initiated.','Success');}).catch((error) => {
        console.log(error);
        this.displaySpinner = false;
        this.showToast({
            title: "Error",
            message: "Something went wrong. Please try again later.",
            variant: "error",
        });
      });
      this.isExecuting = true;
      await this.sleep(2000);
      this.isExecuting = false;
    }
  
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms));
    }

    showToast(title, message, variant) {
      const evt = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
      });
      this.dispatchEvent(evt);
  }

}