'use strict';

const React = require('react');
const PropTypes = require('prop-types');
const getNow = require('./../../../../libs/getNow');

const ModalPage = require('./../../modalpage/modalPage.jsx');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    InputDate = require('../../input-date/input-date.jsx'),
    ICON = 'execute';


class ButtonTask extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.state = {
            showModal: false,
            seisuga: getNow()
        };
        this.handleClick = this.handleClick.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
    }

    handleClick(e) {
        this.setState({showModal: true});
    }

    render() {
        let value = this.props.value ? this.props.value : 'Täitmine';
        return (
            <div>
                <Button
                    show={true}
                    value={value}
                    ref="btnTask"
                    style={styles.button}
                    disabled={false}
                    onClick={this.handleClick}>
                    <img ref="image" src={styles.icons[ICON]}/>
                </Button>
                {this.state.showModal ?
                    <ModalPage
                        modalPageBtnClick={this.modalPageClick}
                        modalPageName={value}
                        show={true}
                        modalObjects={['btnOk', 'btnCancel']}
                    >
                        {`Kas käivata "${value}" ?`}
                        <InputDate title='Seisuga '
                                   name='kpv'
                                   value={this.state.seisuga}
                                   ref='input-kpv'
                                   readOnly={false}
                                   onChange={this.handleInputChange}/>

                    </ModalPage> : null
                }
            </div>
        )
    }

    modalPageClick(btnEvent) {
        this.setState({showModal: false});
        if (btnEvent === 'Ok') {
            this.props.onClick(this.props.value, this.state.seisuga);
        }
    }

    //will save value
    handleInputChange(name, value) {
        this.setState({seisuga: value});
    }

}

ButtonTask.defaultProps = {
    disabled: false,
    show: true
};

module.exports = ButtonTask;