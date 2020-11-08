'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./styles'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    Button = require('./../../components/button-register/button-register.jsx'),
    BtnInfo = require('./../button-register/button-info/index.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');

const GRID_CONFIG = require('./../../../config/constants').logs.gridConfig;

class ShowLogs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: !!this.props.data.length
        };

        this.modalPageClick = this.modalPageClick.bind(this);
    }

    render() {
        return (this.state.show ? this.modalPage() : (
                <Button
                    ref="btnLogs"
                    value='Loggid'
                    show={this.props.show}
                    onClick={(e) => this.handleClick(e)}>
                    <img ref='image' src={styles.button.icon}/>
                </Button>
            )

        )
    }

    handleClick() {
        this.props.onClick();
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = ['btnOk'];

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
                    <DataGrid gridData={this.props.data.data}
                              gridColumns={GRID_CONFIG}
                              showToolBar={false}
                              ref="data-grid"/>
                </div>
            </ModalPage>);
    }

    modalPageClick(event) {
        if (event === 'Ok') {

            // показать новое значение
            this.setState({show: false});
        }
    }

}

ShowLogs.propTypes = {
    show: PropTypes.bool
};

ShowLogs.defaultProps = {
    show: true
};

module.exports = ShowLogs;
