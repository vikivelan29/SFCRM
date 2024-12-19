import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import CASE_EMAIL_DRAFT_FIELD from '@salesforce/schema/Case.eBOT_Email_Draft__c';
import CASE_EMAIL_DRAFT_FIELD_INITIAL from '@salesforce/schema/Case.eBOT_Email_Draft_initial__c';
import createEmailDraft from '@salesforce/apex/ABFL_EmailTemplatePreloader.createEmailDraft';
const CASE_FIELDS = [CASE_EMAIL_DRAFT_FIELD,CASE_EMAIL_DRAFT_FIELD_INITIAL];
export default class ChildModal extends LightningElement {
    @api recordId; // Automatically passed when invoked from the Case Quick Action
    @track emailDraft = ''; // Stores the email draft text
    @track isEditable = false; // Toggles between read-only and editable modes
    @track emailTemplateId = '00XNy000000K2inMAC';
    @track contactId = '003Bl00000In3gjIAB' //fetch it dynamically from case record
    // Fetch the email draft from the Case record
    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.emailDraft = data.fields.eBOT_Email_Draft__c.value != null ? data.fields.eBOT_Email_Draft__c.value : data.fields.eBOT_Email_Draft_initial__c.value;
        } else if (error) {
            console.error('Error fetching Case data:', error);
        }
    }

    // Handle the Modify button to make the field editable
    handleModify() {
        this.isEditable = true;
    }

    // Handle changes to the email draft field
    handleEmailContentChange(event) {
        this.emailDraft = event.target.value;
    }

    // Save the updated draft with confirmation
    handleSave() {
        const isConfirmed = window.confirm('Are you sure you want to save the changes?');
        if (isConfirmed) {
            const fields = {
                Id: this.recordId,
                eBOT_Email_Draft__c: this.emailDraft
            };

            updateRecord({ fields })
                .then(() => {
                    this.isEditable = false; // Revert to read-only mode
                    alert('Changes saved successfully.');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    let retURL = this.recordId
                    //const sendEmailUrl = `/email/author/emailauthor.jsp?p3_lkid=${this.recordId}&template_id=${this.emailTemplateId}&retURL=/${retURL}&p2_lkid=${this.contactId}`;
        
                    // Redirect the user to the Send Email page
                    //window.open(sendEmailUrl, '_self');
                    this.handleOpenEmailTab()
                    this.redirectToCaseDetail()
                    
                })
                .catch(error => {
                    console.error('Error updating Case record:', error);
                });
        }
    }

    // Close the modal without saving changes
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    redirectToCaseDetail() {
        // Use NavigationMixin to redirect to the Case detail page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }
       handleOpenEmailTab() {
        createEmailDraft({ caseId: this.recordId, subject: 'Test', body: this.emailDraft, toAddress: 'mrinal.tripathi@in.ey.com',  emailTemplateId: this.emailTemplateId})
            .then((draftId) => {
                // Open the Email tab with the draft preloaded
                
            })
            .catch((error) => {
                console.error('Error creating email draft:', error);
                alert('Failed to preload email fields. Please contact your administrator.');
            });
    } 
}