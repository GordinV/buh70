'use strict';

const React = require('react');
const PropTypes = require('prop-types');
const DocContext = require('./../../../doc-context.js');
const URL = '/newApi/noticed';
const fetchData = require('./../../../../libs/fetchData');
const ModalPage = require('./../../modalpage/modalPage.jsx'),
    DataGrid = require('../../data-grid/data-grid.jsx'),
    Button = require('./../../button-register/button-register.jsx'),
    BtnInfo = require('./../button-info/index.jsx');

const styles = require('./styles'),
    ICON = 'info';
const GRID_CONFIG = require('./../../../../config/constants').noticed.gridConfig;


class ButtonTeatised extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value || 'Teatised',
            data: [],
            show: false
        };
        this.fetchNoticed = this.fetchNoticed.bind(this);
        this.fetchData = this.fetchData.bind(this);
        this.modalPage = this.modalPage.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
    }

    /**
     * пишем делаем запрос по итогу загрузки
     */
    componentDidMount() {
        this.fetchData('select');
        this.fetchNoticed()
    }


    handleClick(e) {
        this.setState({show: true});
    }

    /*
        Будет запрашивать извещения
     */
    fetchNoticed() {
        setInterval(() => {
            this.fetchData('select')
        }, 1000 * 60);
    }

    /**
     * Выполнит запросы
     */
    fetchData(action) {
        let params = {userId: DocContext.getUserId, action: action};

        try {
            fetchData.fetchDataPost(URL, params)
                .then(response => {
                    if (response.status && response.status == 401) {
                        console.error('Error 401, redirect');
                        document.location = `/login`;
                    }

                    // если запрашиваем события и они есть
                    if (response && action == 'select') {
                        // есть ответ
                        let newTeatised = response.data && response.data.data ? response.data.data.length : 0;
                        let value = newTeatised ? `Teatised (${newTeatised})` : `Teatised`;
                        if (newTeatised && newTeatised !== this.state.data.length) {
                           let audio = new Audio('/audio/notice.wav');
                            audio.play();
                        }

                        this.setState({data: response.data.data, value: value});
                    }
                })
                .catch(error => {
                    console.error('received error-> ', error);
                    if (error) {
                        document.location = `/login`;
                    }
                });

        } catch (e) {
            console.error(e);
        }
    }


    render() {
        return this.state.show ? this.modalPage() : (<Button
            value={this.state.value}
            ref="btnTeatised"
            style={styles.button}
            show={this.props.show ? this.props.show : true}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>)
    }

    modalPage() {
        let modalObjects = ['btnOk', 'btnCancel'];

        return (
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Loggid'>
                <div style={styles.btnInfo}>
                    <BtnInfo ref='btnInfo'
                             value={''}
                             docTypeId={'logid'}
                             show={true}/>
                </div>
                <div ref="grid-row-container">
                    <DataGrid gridData={this.state.data}
                              gridColumns={GRID_CONFIG}
                              showToolBar={false}
                              ref="data-grid"/>
                </div>
            </ModalPage>);
    }

    modalPageClick(event) {
        if (event === 'Ok') {
            this.fetchData('update');

            // закроем окно и поменяем статус извещений
            this.setState({show: false, data: [], value: 'Teatised'});
        } else {
            // закроем окно
            this.setState({show: false});
        }
    }

}

ButtonTeatised.propTypes = {
    value: PropTypes.string
};


ButtonTeatised.defaultProps = {
    disabled: false,
    show: true,
    value: 'Teatised'
};

module.exports = ButtonTeatised;