//
// UI Configuration
//

// Display resolution
`define SCREEN_WIDTH  1280
`define SCREEN_HEIGHT 720

// Widget count for the hand-written demo in rtl/pixel_renderer.v.
// JSON-generated scenes are not reflected here because the generator emits
// a separate pixel_renderer.v and does not consume this header.
`define NUM_WIDGETS 6

// Background color
`define BG_COLOR_R 8'd5
`define BG_COLOR_G 8'd7
`define BG_COLOR_B 8'd12
