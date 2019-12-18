'use strict';

const PropTypes = require('prop-types');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');

const React = require('react'),
    styles = require('./styles'),
    Button = require('./../../components/button-register/button-register.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');

class UploadButton extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: false, //модальное окно закрыто
            selectedFile: null,
            response: null,
            loading: false
        };

        this.modalPageClick = this.modalPageClick.bind(this);
        this.onChangeHandler = this.onChangeHandler.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.fecthData = this.fecthData.bind(this);
    }

    render() {
        return (this.state.show ? this.modalPage() : (
                <Button
                    ref="btnUpload"
                    value='Import'
                    show={true}
                    onClick={(e) => this.handleClick(e)}>
                    <img ref='image' src={styles.button.icon}/>
                </Button>
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

        return (
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-upload"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Import'>
                <div style={styles.docRow}>
                    <input type="file" name="file" onChange={this.onChangeHandler}/>
                </div>
                <div>
                    {this.state.response ? <span>{this.state.response}</span> : null}
                </div>
            </ModalPage>);
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
                    this.setState({response: response.data}, () => {
                        // close modal
                        setTimeout(() => {
                            this.setState({response: null, show: false, loading: false});
                        }, 1000);
                    });
                    if (this.props.onClick) {
                        this.props.onClick(response.data);
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
}

UploadButton.propTypes = {
    show: PropTypes.bool
};

UploadButton.defaultProps = {
    show: false
};

module.exports = UploadButton;
