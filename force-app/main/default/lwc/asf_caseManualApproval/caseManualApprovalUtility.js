import APPROVER1 from '@salesforce/schema/ASF_Case_Approv__c.Approver_01__c';
import APPROVER2 from '@salesforce/schema/ASF_Case_Approv__c.Approver_02__c';
import APPROVER3 from '@salesforce/schema/ASF_Case_Approv__c.Approver_03__c'; 
import APPROVER4 from '@salesforce/schema/ASF_Case_Approv__c.Approver_04__c'; 
import APPROVER5 from '@salesforce/schema/ASF_Case_Approv__c.Approver_05__c';
import RECAT_APPROVER1 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_01__c';
import RECAT_APPROVER2 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_02__c';
import RECAT_APPROVER3 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_03__c';
import RECAT_APPROVER4 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_04__c';
import RECAT_APPROVER5 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_05__c';
import APPROVALTYPE from '@salesforce/schema/ASF_Case_Approv__c.Approval_Type__c';
import REQCOMMENTS from '@salesforce/schema/ASF_Case_Approv__c.Requestor_Comments__c';

export const modalStates={
    
    CASE_APPROVAL_FIELDS:[
        {
            fieldAPIName : APPROVER1.fieldApiName,
            fieldlabel : 'Approver 01',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : true,
            id: 'caseMaunalApproval_01',
            showBinIcon:false,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : APPROVER2.fieldApiName,
                        isRequied : true
                    },
                    {
                        fieldAPIName : APPROVALTYPE.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"",
                isVisible: false,
            },
            classDisplay:"",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : APPROVER2.fieldApiName,
            fieldlabel : 'Approver 02',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_03',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : APPROVER3.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName,
                        fieldAPIName : APPROVER2.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:APPROVER2.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVALTYPE.fieldApiName
                    },
                    {
                        fieldAPIName: APPROVER3.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVER4.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVER5.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : APPROVER3.fieldApiName,
            fieldlabel : 'Approver 03',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_05',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : APPROVER4.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName,
                        fieldAPIName : APPROVER2.fieldApiName,
                        fieldAPIName : APPROVER3.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:APPROVER3.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVER5.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVER4.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER2.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : APPROVER4.fieldApiName,
            fieldlabel : 'Approver 04',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_07',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : APPROVER5.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName,
                        fieldAPIName : APPROVER2.fieldApiName,
                        fieldAPIName : APPROVER3.fieldApiName,
                        fieldAPIName : APPROVER4.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:APPROVER5.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVER4.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER3.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : APPROVER5.fieldApiName,
            fieldlabel : 'Approver 05',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_08',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: false,
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER1.fieldApiName,
                        fieldAPIName : APPROVER2.fieldApiName,
                        fieldAPIName : APPROVER3.fieldApiName,
                        fieldAPIName : APPROVER4.fieldApiName,
                        fieldAPIName : APPROVER5.fieldApiName
                    }
                ]
                
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:APPROVER5.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : APPROVER4.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        }
    ],
    RECAT_APPROVAL_FIELDS:[
        {
            fieldAPIName : RECAT_APPROVER1.fieldApiName,
            fieldlabel : 'Approver 01',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : true,
            id: 'caseMaunalApproval_01',
            showBinIcon:false,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : RECAT_APPROVER2.fieldApiName,
                        isRequied : true
                    },
                    {
                        fieldAPIName : APPROVALTYPE.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"",
                isVisible: false,
            },
            classDisplay:"",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : RECAT_APPROVER2.fieldApiName,
            fieldlabel : 'Approver 02',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_03',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : RECAT_APPROVER3.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName,
                        fieldAPIName : RECAT_APPROVER2.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:RECAT_APPROVER2.fieldApiName
                    },
                    {
                        fieldAPIName:APPROVALTYPE.fieldApiName
                    },
                    {
                        fieldAPIName: RECAT_APPROVER3.fieldApiName
                    },
                    {
                        fieldAPIName:RECAT_APPROVER4.fieldApiName
                    },
                    {
                        fieldAPIName:RECAT_APPROVER5.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : RECAT_APPROVER3.fieldApiName,
            fieldlabel : 'Approver 03',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_05',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : RECAT_APPROVER4.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName,
                        fieldAPIName : RECAT_APPROVER2.fieldApiName,
                        fieldAPIName : RECAT_APPROVER3.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:RECAT_APPROVER3.fieldApiName
                    },
                    {
                        fieldAPIName:RECAT_APPROVER5.fieldApiName
                    },
                    {
                        fieldAPIName:RECAT_APPROVER4.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER2.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : RECAT_APPROVER4.fieldApiName,
            fieldlabel : 'Approver 04',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_07',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: true,
                addFields:[
                    {
                        fieldAPIName : RECAT_APPROVER5.fieldApiName,
                        isRequied : true
                    }
                ],
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName,
                        fieldAPIName : RECAT_APPROVER2.fieldApiName,
                        fieldAPIName : RECAT_APPROVER3.fieldApiName,
                        fieldAPIName : RECAT_APPROVER4.fieldApiName
                    }
                ]
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName:RECAT_APPROVER5.fieldApiName
                    },
                    {
                        fieldAPIName:RECAT_APPROVER4.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER3.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        },
        {
            fieldAPIName : RECAT_APPROVER5.fieldApiName,
            fieldlabel : 'Approver 05',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_08',
            showBinIcon:true,
            anchorAddAction:{
                action:"ADD",
                isVisible: false,
                hideAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER1.fieldApiName,
                        fieldAPIName : RECAT_APPROVER2.fieldApiName,
                        fieldAPIName : RECAT_APPROVER3.fieldApiName,
                        fieldAPIName : RECAT_APPROVER4.fieldApiName,
                        fieldAPIName : RECAT_APPROVER5.fieldApiName
                    }
                ]
                
            },
            anchorRemoveAction:{
                action:"REMOVE",
                isVisible: true,
                removeFields: [
                    {
                        fieldAPIName : RECAT_APPROVER5.fieldApiName
                    }
                ],
                showAddDeleteIcon:[
                    {
                        fieldAPIName : RECAT_APPROVER4.fieldApiName
                    }
                ]
            },
            classDisplay:"slds-hide",
            showError:true,
            errorMessage:""
        }
    ]
}
export const errorCodes={
    LOGGEDINUSERAPPROVER : "Approvals cannot be assigned to yourself.",
    APPROVERALREADYSELECTED : "Approver already selected.",
    GARBAGEVALUEINLOOKUP : 'Select an option from the picklist or remove the search term',
    WARNINGAPPROVALREMOVAL : 'Before removing approver field, please remove garbage values from '
}
export const staticFields={
    APPROVALSTATISFIELDS:[
        {
            fieldAPIName : APPROVALTYPE.fieldApiName,
            fieldlabel : 'Approval Type',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : false,
            id: 'caseMaunalApproval_04',
            showBinIcon:false,
            anchorAddAction:{
                action:"",
                isVisible: false
            },
            anchorRemoveAction:{
                action:"",
                isVisible: false
            },
            classDisplay:"slds-hide",
            defaulSelectedOption:"Parallel - All to approve",
            showError:true,
            errorMessage:"",
            fieldClassList : "slds-p-around_xx-small"
        },
        {
            fieldAPIName : REQCOMMENTS.fieldApiName,
            fieldlabel : 'Requestor Comments',
            displayType:
                {
                  radioButton : false,
                  input : true
                },
            readOnly: false,
            requiredField : true,
            id: 'caseMaunalApproval_02',
            showBinIcon:false,
            anchorAddAction:{
                action:"",
                isVisible: false
            },
            anchorRemoveAction:{
                action:"",
                isVisible: false
            },
            classDisplay:"custom-TextArea-Max-Width",
            showError:true,
            errorMessage:"",
            isStaticField : true,
            fieldClassList : "custom-TextArea-Max-Width slds-p-around_xx-small"
        }
    ]
}