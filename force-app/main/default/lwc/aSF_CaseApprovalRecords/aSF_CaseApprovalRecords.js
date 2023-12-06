import { LightningElement, track, wire, api } from 'lwc';
import getApprovalHistory from '@salesforce/apex/ASF_ApprovalDetails.getApprovalHistory';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class ASF_CaseApprovalRecords extends NavigationMixin(LightningElement) {
    @api recordId;
    accData;
    approvalData;
    errorData;
    value;
    event2;
    event;
    recordCheckId;
    areDetailsVisible = false;
    checklistData;
    wiredAccountsResult;
    wiredApprovalResult;
    recordPageUrl;
    recordNumber;
    rowNumber;
    hasRecord = false;
    stepStarted;
    dataEditing = [];
    apprApexReturnValue;



    /*@wire(getApprovalHistory, { recordId: '$recordId' })
    wiredApprovals({ error, data }) {
      */
    @wire(getApprovalHistory, { recordId: '$recordId' })
    wiredApprovals(result) {
        this.apprApexReturnValue = result;
        if (result.data) {
            this.wiredApprovalResult = result.data;
            let temp = JSON.parse(JSON.stringify(result.data));

            let temp_approvals = [];
            for (let i in this.wiredApprovalResult) {

            }
            for (let i in this.wiredApprovalResult) {
                const approval = new Object();
                approval.approvalType = this.wiredApprovalResult[i].approvalType;
                approval.id = this.wiredApprovalResult[i].caseApprovalId;
                approval.stg = this.wiredApprovalResult[i].currStg;
                let temp = [];
                let stps = this.wiredApprovalResult[i].stepDetails;
                for (let j in stps) {
                    const step = new Object();
                    step.actorname = stps[j].actorName;
                    if (stps[j].stepName.trim().toLowerCase() == 'removed') {
                        step.name = "Recalled";
                    }
                    else {
                        step.name = stps[j].stepName;
                    }

                    temp.push(step);
                }

                approval.steps = temp;
                temp_approvals.push(approval);
            };
            this.dataEditing = temp_approvals;

        }
        else if (result.error) {
            this.error = result.error;
            this.approvalData = undefined;
        }
    }

    handleClick(event) {
        let selectTaskID = event.target.dataset.id;
        console.log("clicked", selectTaskID);
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: selectTaskID,
                actionName: 'view',
            },
        })
    }
    connectedCallback() {
        this.event2 = setInterval(() => {
            refreshApex(this.apprApexReturnValue);
        }, 5000);
    }




}