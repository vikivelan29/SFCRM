import DMS_File_Name from '@salesforce/label/c.DMS_File_Name';
import Manual_Synching from '@salesforce/label/c.Manual_Synching';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
export const getColumnsStatic = (result, businessUnit) =>  {

    let DEFAULT = [
        {
            label: DMS_File_Name,
            fieldName: 'accLink',
            type: 'url',
            fixedWidth: 260,
            typeAttributes: { label: { fieldName: 'File_Name__c' }, target: '_self' }
        },
        {
            fieldName: 'Error_Description__c',
            label: 'Status',
            type: 'url',
            typeAttributes: { label: { fieldName: 'dynamicIconText' }, target: '_self' },
            cellAttributes: { iconName: { fieldName: 'dynamicIcon' }, iconAlternativeText: {fieldName: 'dynamicIconText' } }
        }
        ,
        ...result.map(col => ({
            label: col.MasterLabel,
            fieldName: col.Api_Name__c,
            type: col.Data_Type__c,
            cellAttributes: { alignment: 'left' }
        })),
        {
            label: 'Actions',
            type: 'button',
            typeAttributes: {
                label: 'View Link',
                name: 'viewLink',
                variant: 'base',
                disabled: { fieldName: 'showButtons' }
            }
        },
        {
            label: Manual_Synching,
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'actionText' },
                name: 'manualSync',
                variant: 'base',
                disabled: { fieldName: 'showButtonsSynch' }
            }
        }
    ];
    let ABSLI  = [
        {
            label: DMS_File_Name,
            fieldName: 'accLink',
            type: 'url',
            fixedWidth: 260,
            typeAttributes: { label: { fieldName: 'File_Name__c' }, target: '_self' }
        },
        {
            fieldName: 'Status__c',
            label: 'Status',
            type: 'text'
        }
        ,
        {
            fieldName: 'LastModifiedDate',
            label: 'Uploaded Date',
            type: 'date',
            typeAttributes:{
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit"
            }
        },
        {
            label: 'Actions',
            type: 'button',
            typeAttributes: {
                label: 'View Link',
                name: 'viewLink',
                variant: 'base',
                disabled: { fieldName: 'showButtons' }
            }
        }
    ];

    if(businessUnit == ABSLI_BU){
        return ABSLI;
    } else {
        return DEFAULT;
    }
}