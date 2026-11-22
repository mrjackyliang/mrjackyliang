'use client';

import {
  Box,
  Button,
  Grid,
  Tab,
  Tabs,
} from '@mui/material';
import _ from 'lodash';
import React, {
  JSX,
  SyntheticEvent,
  useEffect,
  useState,
} from 'react';
import MonacoEditor from '@monaco-editor/react';

/**
 * Code editor.
 *
 * @constructor
 *
 * @since 1.0.0
 */
function CodeEditor() {
  return (
    <Box
      sx={{
        backgroundColor: '#1e1e1e',
        width: 'calc(100vw - 16px)',
        height: 'calc(100vh - 16px - 48px)',
      }}
    >
      <MonacoEditor
        width="100%"
        height="100%"
        defaultLanguage="js"
        theme="vs-dark"
        onChange={(value) => console.log('Monaco editor changed:', value)}
        options={{
          dragAndDrop: false,
          wordWrap: 'on',
          inlineSuggest: {
            enabled: true,
            mode: 'subwordSmart',
          },
        }}
      />
    </Box>
  );
}

/**
 * Code editor tabs.
 *
 * @constructor
 *
 * @since 1.0.0
 */
export function CodeEditorTabs(): JSX.Element {
  const [tabs, setTabs] = useState([{
    id: 0,
    name: 'Editor 1',
    component: (
      <CodeEditor />
    ),
  }]);
  const [currentTab, setCurrentTab] = useState(0);

  /**
   * Add tab.
   *
   * @returns {void}
   *
   * @since 1.0.0
   */
  const addTab = (): void => {
    const nextId = tabs[tabs.length - 1].id + 1;
    const newTab = {
      id: nextId,
      name: `Editor ${nextId + 1}`,
      component: (
        <CodeEditor />
      ),
    };

    // Add a new tab.
    setTabs([...(tabs), newTab]);

    // Move current view to recently added tab (based on length before tab was created).
    setCurrentTab(tabs.length);
  };

  /**
   * Delete tab.
   *
   * @param {{ id: number, name: string, component: JSX.Element }} tabToDelete - Tab to delete.
   *
   * @returns {void}
   *
   * @since 1.0.0
   */
  const deleteTab = (tabToDelete: { id: number, name: string, component: JSX.Element }): void => {
    // Don't allow user to delete last available tab.
    if (tabs.length === 1) {
      return;
    }

    setTabs(tabs.filter((tab) => !_.isEqual(tab, tabToDelete)));

    // If current tab is to the right of the deleted tab.
    if (currentTab > _.findIndex(tabs, tabToDelete)) {
      setCurrentTab(currentTab - 1);
    }

    // If deleting the last tab and index of current tab is the deleted tab.
    if (
      _.findIndex(tabs, tabToDelete) === tabs.length - 1
      && currentTab === _.findIndex(tabs, tabToDelete)
    ) {
      setCurrentTab(_.findIndex(tabs, tabToDelete) - 1);
    }
  };

  /**
   * Tab on change.
   *
   * @param {SyntheticEvent} event    - Event.
   * @param {any}            newValue - New value.
   *
   * @since 1.0.0
   */
  const tabOnChange = (event: SyntheticEvent, newValue: any) => {
    // Prevents tab change if user intended to click on the "✕" link inside button.
    if (_.get(event, ['target', 'localName']) === 'button') {
      setCurrentTab(newValue);
    }
  };

  useEffect(() => {
    console.log('Changed tab:', currentTab);
  }, [currentTab]);

  return (
    <Box>
      <Grid container>
        <Grid item xs={11}>
          <Tabs
            value={currentTab}
            onChange={(event, newValue) => tabOnChange(event, newValue)}
            variant="scrollable"
            scrollButtons={false}
          >
            {
              tabs.map((tab) => (
                <Tab
                  key={tab.id}
                  label={tab.name}
                  icon={(tabs.length > 1) ? (
                    <Button
                      disableRipple
                      onClick={() => deleteTab(tab)}
                      sx={{
                        minWidth: 0,
                        padding: 0,
                        textDecoration: 'none',
                      }}
                    >
                      ✕
                    </Button>
                  ) : undefined}
                  iconPosition="end"
                  sx={{
                    minHeight: 48,
                  }}
                />
              ))
            }
          </Tabs>
        </Grid>
        <Grid item xs={1}>
          <Button
            sx={{
              backgroundColor: '#1e1e1e',
              color: '#ffffff',
              fontSize: 21,
              width: '100%',
              minWidth: 0,
              borderRadius: 0,
              '&:hover': {
                backgroundColor: '#333333',
              },
            }}
            onClick={() => addTab()}
          >
            +
          </Button>
        </Grid>
      </Grid>
      {
        tabs.map((tab) => (
          <Box key={tab.id} hidden={currentTab !== _.findIndex(tabs, tab)}>
            {tab.component}
          </Box>
        ))
      }
    </Box>
  );
}
