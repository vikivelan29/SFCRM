import { LightningElement,api } from 'lwc';
import sendMail from '@salesforce/apex/ABSLI_CaseIntegrationHelper.sendMail';
import changeAttachments from '@salesforce/apex/ABSLI_CaseIntegrationHelper.changeAttachments';
import { NavigationMixin } from 'lightning/navigation';

export default class Absli_emailcomposer extends NavigationMixin(LightningElement) {
    previewMode = false;
    @api record;
    @api recid;
    loading = false;

    changeHandler(event) {
        this.record = JSON.parse(JSON.stringify(this.record));
        const fieldName = event.target.name;
        this.record[fieldName] = event.target.value;
    }

    connectedCallBack(){
        console.log('e');
    }
    handleModes(e){
        console.log(this.emailTemplate);
        this.previewMode = !this.previewMode;
    }

    sendMail(e){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid){
            this.loading = true;
            sendMail({ recId: this.recid,
                emailWrapperStr:JSON.stringify(this.record) })
            .then(result => {
                this.loading = false;
                this.close(true);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.loading = false;
            })
        }
    }

    removeAttachment(e){
        this.changeAttachment(true,e.target.dataset.contentid);
    }

    addAttachment(e){
        var contentId;
        if(e.detail.files){
            contentId = e.detail.files[0].contentVersionId;
        }
        this.changeAttachment(false,contentId);
    }

    changeAttachment(isDelete,contentid){
        this.loading = true;
        changeAttachments({ recId: this.recid,
                            attachmentId: contentid,
                            deleteAttachment: isDelete })
            .then(result => {
            this.record = result;
            this.error = undefined;
            this.loading = false;
            })
            .catch(error => {
            this.error = error;
            this.loading = false;
            })
    }

    viewRecord(e){
        this[NavigationMixin.Navigate](
            {
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview',
                },
                state : {
                    recordIds: e.target.dataset.contentid
                }
            }
        );
    }

    close(isEmailSent){
        const selectEvent = new CustomEvent('closemodal', { detail : isEmailSent});
       this.dispatchEvent(selectEvent);
    }
}