'use strict';

const React = require('react');
const PropTypes = require('prop-types');
const getNow = require('./../../../../libs/getNow');

const ModalPage = require('./../../modalpage/modalPage.jsx');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    InputDate = require('../../input-date/input-date.jsx'),
    InputNumber = require('../../input-number/input-number.jsx'),
    ICON = 'execute';


class ButtonTask extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.state = {
            showModal: false,
            seisuga: getNow(),
            kogus: 0,
            kas_kond: false
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
                    ref={'btnTask' || this.props.ref}
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
                        {this.props.showDate ? <InputDate title='Seisuga '
                                                          name='kpv'
                                                          value={this.state.seisuga}
                                                          ref='input-kpv'
                                                          readOnly={false}
                                                          onChange={this.handleInputChange}/> : null}

                        {this.props.showKogus ? <InputNumber title={this.props.title ? this.props.title : 'Väärtus'}
                                                             name='kogus'
                                                             value={Number(this.state.kogus)}
                                                             ref='input-kogus'
                                                             readOnly={false}
                                                             onChange={this.handleInputChange}/> : null}
                    </ModalPage> : null
                }
            </div>
        )
    }

    modalPageClick(btnEvent) {
        this.setState({showModal: false});
        if (btnEvent === 'Ok') {
            this.props.onClick(this.props.value, this.props.showKogus ? this.state.kogus : this.state.seisuga, this.state.kas_kond);
        }
    }

    //will save value
    handleInputChange(name, value) {
        switch (name) {
            case 'kpv':
                this.setState({seisuga: value});
                break;
            case 'kogus':
                this.setState({kogus: value});
                break;
            case 'kas_kond':
                this.setState({kas_kond: value});
                break;

        }
    }

}

ButtonTask.defaultProps = {
    disabled: false,
    show: true,
    showDate: true,
    showKogus: false,
    showKond: false
};

module.exports = ButtonTask;