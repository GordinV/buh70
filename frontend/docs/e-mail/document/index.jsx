'use strict';
const React = require('react');
const PropTypes = require('prop-types');
const fetchData = require('./../../../../libs/fetchData');
const DocContext = require('../../../doc-context.js');

const InputText = require('../../../components/input-text/input-text.jsx'),
    Form = require('../../../components/form/form.jsx'),
    BtnEmail = require('./../../../components/button-register/button-email/index.jsx'),
    BtnGetPdf = require('./../../../components/button-register/button-pdf/index.jsx'),
    ToolbarContainer = require('../../../components/toolbar-container/toolbar-container.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    BtnInfo = require('./../../../components/button-register/button-info/index.jsx'),
    styles = require('./styles');


/**
 * Класс реализует документ справочника признаков.
 */
class Email extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            email: null,
            subject: null,
            context: null,
            attachment: null,
            warningType: null,
            warning: null
        };

        this.btnEmailClickHandler = this.btnEmailClickHandler.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleBtnGetPdf = this.handleBtnGetPdf.bind(this);

    }

    render() {
        let hasEmail = !!this.state.email;
        const warningStyle = styles[this.state.warningType] ? styles[this.state.warningType] : null;

        return (
            <Form>
                <ToolbarContainer>
                    <BtnEmail
                        ref='btnEmail'
                        docTypeId={DocContext.docTypeId}
                        onClick={this.btnEmailClickHandler}
                        disabled={!hasEmail}
                    />
                    <BtnInfo ref='btnInfo'
                             value={''}
                             docTypeId={'email_document'}
                             show={true}/>

                </ToolbarContainer>
                <ToolbarContainer ref='toolbar-container'>
                    <div className='doc-toolbar-warning' style={warningStyle}>
                        {this.state.warning ? <span>{this.state.warning}</span> : null}
                    </div>
                </ToolbarContainer>

                <InputText
                    title="Adressaat: "
                    name='email'
                    ref="input-email"
                    value={this.state.email || ''}
                    onChange={this.handleInputChange}
                />
                <InputText
                    title="Pealkiri: "
                    name='subject'
                    ref="input-subject"
                    value={this.state.subject || ''}
                    onChange={this.handleInputChange}
                />
                <TextArea title="Sisu"
                          name='context'
                          ref="textarea-context"
                          onChange={this.handleInputChange}
                          value={this.state.context || ''}
                />
                <BtnGetPdf
                    value={`doc.pdf`}
                    name='btnGetPdf'
                    ref='btnGetPdf'
                    onClick={this.handleBtnGetPdf}
                />
            </Form>

        )
    }

    handleBtnGetPdf() {
        // get url
        let url;
        if (DocContext['email-params'].queryType == 'id') {
            url = `/pdf/${DocContext.docTypeId}/${DocContext.userData.uuid}/${DocContext['email-params'].docId}`;
            window.open(`${url}`);
        } else {
            let params = encodeURIComponent(`${DocContext['email-params'].sqlWhere}`);
            let filter = encodeURIComponent(`${JSON.stringify(DocContext['email-params'].filterData)}`);

            if (DocContext['email-params'].filterData.length) {
                url = `/pdf/${DocContext.docTypeId}/${DocContext.userData.uuid}/${filter}`;

            } else {
                url = `/pdf/${DocContext.docTypeId}/${DocContext.userData.uuid}/0`;
            }
            window.open(`${url}/${params}`);
        }
    }

    handleInputChange(inputName, inputValue) {
        const data = this.state;
        data[inputName] = inputValue;
        this.setState(data);
    }

    btnEmailClickHandler() {
        const params = {
            docTypeId: DocContext['email-params'].docTypeId,
            id: DocContext['email-params'].queryType == 'id' ? DocContext['email-params'].docId : null,
            sqlWhere: DocContext['email-params'].queryType == 'id' ? null : DocContext['email-params'].sqlWhere,
            filterData: DocContext['email-params'].queryType == 'id' ? null : DocContext['email-params'].filterData,
            module: DocContext.module,
            userId: DocContext.userData.userId,
            uuid: DocContext.userData.uuid,
            context: this.state.context,
            email: this.state.email,
            subject: this.state.subject
        };

        this.fetchData('Post', '/email/sendPrintForm', params).then((response) => {
            if (response.status === 200) {
                this.setState({
                    warning: 'Email saadetud edukalt, suunatan ...',
                    warningType: 'ok',
                }, () => {
                    setTimeout(() => {
                        this.props.history.goBack();
                    }, 10000);
                });
            } else {
                this.setState({
                    warning: 'Tekkis viga',
                    warningType: 'error',
                });
            }

        }).catch(error => {
            this.setState({
                warning: `Tekkis viga ${error.error}`,
                warningType: 'error',
            });
            console.error(error);
        });
    }

    /**
     * Выполнит запросы
     */
    fetchData(protocol, api, params) {

        let url = api ? api : `${URL}/${this.props.docTypeId}/${this.state.docId}`;
        let method = 'fetchDataPost';

        if (protocol) {
            //request call not default
            method = 'fetchData' + protocol;
        }

        return new Promise((resolved, rejected) => {
            fetchData[method](url, params).then(response => {
                    if (response.status && response.status === 401) {
                        document.location = `/login`;
                    }

                    if (response.data) {

                        //execute select calls
                        if (response.data.action && response.data.action === 'select') {
                            this.docData = response.data.data[0];

                            // will store required fields info
                            if (response.data.data[0].requiredFields) {
                                this.requiredFields = response.data.data[0].requiredFields;
                            }

                            // will store bpm info
                            if (response.data.data[0].bpm) {
                                this.bpm = response.data.data[0].bpm;
                            }

                            //should return data and called for reload
                            this.setState({reloadData: false, warning: '', warningType: null});
                            resolved(response.data.data[0]);
                        }

                        if (response.data.action && response.data.action === 'save' && response.data.result.error_code) {
                            // error in save
                            this.setState({
                                warning: `Tekkis viga ${response.data.result.error_message}`,
                                warningType: 'error'
                            });
                            return rejected();

                        }

                        return resolved(response.data);
                    } else {
                        console.error('Fetch viga ', response, params);
                        this.setState({
                            warning: `Tekkis viga ${response.data.error_message ? response.data.error_message : ''}`,
                            warningType: 'error'
                        });
                        return rejected();
                    }
                }
            )
        }, error => {
            console.error('doc template Error:', error);
            // possibly auth error, so re-login
            if (this.props.history) {
                this.props.history.push(`/login`);
            }
            return rejected();
        });
    }

}

/*
Email.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};
*/

/*
Email.defaultProps = {
    initData: {},
};
*/


module.exports = (Email);
