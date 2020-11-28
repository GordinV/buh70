'use strict';

const PropTypes = require('prop-types');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');

const React = require('react'),
    styles = require('./styles'),
    Button = require('./../../components/button-register/button-register.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');
const ModalReport = require('./../../components/modalpage/modalpage-report/index.jsx');

class UploadButton extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: false, //модальное окно закрыто
            selectedFile: null,
            response: null,
            loading: false,
            isReport: false,
            txtReport: []

        };

        this.modalPageClick = this.modalPageClick.bind(this);
        this.onChangeHandler = this.onChangeHandler.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.fecthData = this.fecthData.bind(this);
        this.modalReportePageBtnClick = this.modalReportePageBtnClick.bind(this);
    }

    render() {
        return (this.state.show ? this.modalPage() : (
                <div>
                    <Button
                        ref="btnUpload"
                        value={this.props.value ? this.props.value : 'Import'}
                        show={true}
                        onClick={(e) => this.handleClick(e)}>
                        <img ref='image' src={styles.button.icon}/>
                    </Button>
                    <ModalReport
                        show={this.state.isReport}
                        report={this.state.txtReport}
                        modalPageBtnClick={this.modalReportePageBtnClick}>
                    </ModalReport>
                </div>
            )

        )
    }

    handleClick() {
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = this.state.loading ? ['btnCancel'] : ['btnOk', 'btnCancel'];
        let mimeTypes = this.props.mimeTypes ? this.props.mimeTypes : ".csv, .xml";

        return (
            <div>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-upload"
                    show={true}
                    modalPageBtnClick={this.modalPageClick}
                    modalPageName='Import'>
                    <div style={styles.docRow}>
                        <input type="file"
                               name="file"
                               onChange={this.onChangeHandler}
                               accept={mimeTypes}/>
                    </div>
                    <div>
                        {this.state.response ? <span>{this.state.response}</span> : null}
                    </div>
                </ModalPage>

            </div>
        );
    }

    modalPageClick(event) {
        if (event === 'Ok') {
            // показать новое значение

            //upload
            if (this.state.selectedFile) {
                this.setState({loading: true});
                // fetch
                this.fecthData().then((response) => {
                    // show response
                    let l_message = '';
                    if (response.data && response.data.error_message) {
                        l_message = response.data.error_message;
                        if (this.props.onClick) {
                            this.props.onClick(response.data);
                        }

                        // выведем на экран отчет
                        this.setState({
                            show: false,
                            loading: false,
                            isReport: true,
                            txtReport: response.data && response.data.data ? response.data.data: []
                        });

                    } else {

                        // отчета нет, только информация
                        l_message = response.data;
                        this.setState({response: l_message}, () => {

                            // close modal
                            setTimeout(() => {
                                this.setState({response: null, show: false, loading: false});
                            }, 1000);
                        });

                    }

                });
            } else {
                this.setState({response: null, show: false, loading: false});
            }

            if (this.props.onClick) {
                // выполним кастомный метод обработчика события
                this.props.onClick();
            }


        } else {
            this.setState({response: null, show: false, loading: false});
        }
    }

    onChangeHandler(event) {
        this.setState({selectedFile: event.target.files[0]});
    }

    fecthData() {
        const params = {
            parameter: this.props.docTypeId, // параметры
            uuid: DocContext.userData.uuid
        };
        const data = new FormData();
        data.append('file', this.state.selectedFile);
        data.append('uuid', DocContext.userData.uuid);
        data.append('docTypeId', this.props.docTypeId);

        return fetchData.fetchDataPost(`/newApi/upload/`, data);
    }

    /**
     * уберет окно с отчетом
     */
    modalReportePageBtnClick(event) {
        let isReport = event && event == 'Ok' ? false: true;
        this.setState({isReport: isReport})
    }


}

UploadButton.propTypes = {
    show: PropTypes.bool
};

UploadButton.defaultProps = {
    show: false
};

module.exports = UploadButton;
