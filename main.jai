the_window : Window_Type;
window_width  := 1200;
window_height := 800;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware(); // Tell Windows this app know how to HiDpi.

        // Windows is very bad at thread-switching by default unless you do this. Sad.
        Windows.timeBeginPeriod(1);
    }

    the_window = create_window(window_width, window_height, "ck: Image Viewer", window_x=500, window_y=500);
    set_render_target(the_window);

    // Init

    // Parser user arguments.
    args := get_command_line_arguments();
    // The first arg is executable file fullpath name. So we need the second one.
    if args.count == 2 {
        image.filename = args[1];
    }

    #if OS == .WINDOWS {
        // From ~/hello/sailor/foo/bar/image.png to image.png
        name := path_filename(image.filename);
        Windows.SetWindowTextA(the_window, name.data);
    }

    using image;
    {
        texture_load_from_file(*texture, filename);

        w = xx texture.width;
        h = texture.height.(float); // Or you can use cast(float)

        scale = min(window_width / w, window_height / h);

        x = (window_width  - w*scale) / 2.0;
        y = (window_height - h*scale) / 2.0;
    }

    quit := false;
    while !quit {
        // Input
        update_window_events();
        for events_this_frame {
            if it.type == .QUIT quit = true;
            key := it.key_code;

            if key == {
                case .ESCAPE; quit = true;
                case .MOUSE_BUTTON_LEFT;
                    if it.key_pressed {
                        is_dragging = true;
                        offset = pos - mouse_pos;
                    } else {
                        is_dragging = false;
                    }
            }
            if it.type == .MOUSE_WHEEL {
                delta := it.wheel_delta * 0.1; // In my pc, wheel_delta is +120 or -120.
                sensitivity := scale / 100.0;  // So each mouse wheel tick changes the scale by 12%.
                offset := image.pos - mouse_pos;
                new_scale := scale + delta * sensitivity;
                ratio := new_scale / scale;

                scale = new_scale;
                image.pos = mouse_pos + offset * ratio;
            }
        }

        for get_window_resizes() {
            if it.window == the_window {
                window_width = it.width;
                window_height = it.height;
            }
        }

        // Simulate
        update_window(the_window);
        mouse_pos = get_mouse_pos();
        if is_dragging {
            pos = mouse_pos + offset;
        }

        // Render
        draw_one_frame();

        swap_buffers(the_window);
        sleep_milliseconds(10);
    }
}

Image :: struct {
    filename : string;
    texture  : Texture;

    x, y, w, h : float;
    scale := 1.0;

    #overlay (x) pos : v2;


    is_dragging := false;
    offset : v2;
}

// DATA

image : Image;
mouse_pos : v2;


draw_one_frame :: () {
    clear_render_target(0.12, 0.13, 0.14, 1);
    using image;
    set_shader_for_images(*texture);
    immediate_begin();
    immediate_quad(x, y, x+w*scale, y+h*scale, WHITE);
    immediate_flush();
}

get_mouse_pos :: () -> v2 {
    mx, my := get_mouse_pointer_position(the_window, true);
    return .{xx mx, xx my};
}

#run {
    set_build_options_dc(.{output_executable_name="view"});

    #import "Windows_Resources";
    disable_runtime_console();
}

v2 :: Vector2;
v4 :: Vector4;

WHITE :: v4.{1,1,1,1};

#import "Basic";
#import "Compiler";
#import "String";
#import "Math";

#import "Window_Creation";
#import "Input";
#import "Simp";
#import "Print_Vars";
