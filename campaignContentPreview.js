// campaignContentPreview.js
import { LightningElement, api, track, wire } from 'lwc';
import getFileDetails from '@salesforce/apex/CampaignContentController.getFileDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

export default class CampaignContentPreview extends LightningElement {
    @api recordId;
    @track showLoading = false;
    @track fileUrl;
    @track fileData;
    @track error;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef) {
            // Get recordId from state parameters
            const state = pageRef.state;
            const recordIdFromState = state?.c__recordId || state?.recordId;
            
            if (recordIdFromState) {
                console.log('Record ID from state:', recordIdFromState);
                this.recordId = recordIdFromState;
                this.loadFilePreview();
            }
        }
    }

    get isPdfFile() {
        return this.fileData?.contentType === 'application/pdf';
    }

    get isImageFile() {
        return this.fileData?.contentType?.startsWith('image/');
    }

    get isOtherFile() {
        return !this.isPdfFile && !this.isImageFile;
    }

    connectedCallback() {
        console.log('Component initialized with recordId:', this.recordId);
        // Only load if recordId was passed directly
        if (this.recordId) {
            this.loadFilePreview();
        }
    }

    closeModal() {
        console.log('Closing modal');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    loadFilePreview() {
        if (!this.recordId) {
            console.error('Record ID is not available.');
            this.handleError('Record ID is not available. Please make sure the record is selected.');
            return;
        }

        console.log(`Fetching file details for recordId: ${this.recordId}`);
        this.showLoading = true;
        this.error = null;

        getFileDetails({ recordId: this.recordId })
            .then(result => {
                console.log('File details retrieved:', result);
                this.fileData = result;
                this.fileUrl = `/sfc/servlet.shepherd/version/download/${result.contentVersionId}`;
                this.showLoading = false;
            })
            .catch(error => {
                console.error('Error retrieving file details:', error);
                this.handleError(error.body?.message || 'Error retrieving file details');
            });
    }

    downloadFile() {
        if (this.fileUrl) {
            console.log(`Opening file URL: ${this.fileUrl}`);
            window.open(this.fileUrl, '_blank');
        } else {
            console.error('No file URL available for download.');
        }
    }

    handleError(message) {
        console.error('Handling error:', message);
        this.error = message;
        this.showLoading = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }
}
