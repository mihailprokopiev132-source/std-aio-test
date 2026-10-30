
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Capture;

public partial class Form1 : Form
{
    private IntPtr thumbnail = IntPtr.Zero;
    private IntPtr robloxWindow = IntPtr.Zero;

    private const uint RECT_DESTINATION = 0x1;
    private const uint OPACITY = 0x4;
    private const uint VISIBLE = 0x8;
    private const uint SOURCE_CLIENT_AREA = 0x10;

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SIZE
    {
        public int Width;
        public int Height;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ThumbnailProperties
    {
        public uint Flags;
        public RECT Destination;
        public RECT Source;
        public byte Opacity;

        [MarshalAs(UnmanagedType.Bool)]
        public bool Visible;

        [MarshalAs(UnmanagedType.Bool)]
        public bool SourceClientAreaOnly;
    }

    private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("dwmapi.dll")]
    private static extern int DwmRegisterThumbnail(
        IntPtr destination,
        IntPtr source,
        out IntPtr thumbnail);

    [DllImport("dwmapi.dll")]
    private static extern int DwmUnregisterThumbnail(IntPtr thumbnail);

    [DllImport("dwmapi.dll")]
    private static extern int DwmUpdateThumbnailProperties(
        IntPtr thumbnail,
        ref ThumbnailProperties properties);

    [DllImport("dwmapi.dll")]
    private static extern int DwmQueryThumbnailSourceSize(
        IntPtr thumbnail,
        out SIZE size);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(
        EnumWindowsProc callback,
        IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(
        IntPtr hwnd,
        out uint processId);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= 0x08000000 | 0x00000080;
            return cp;
        }
    }

    public Form1()
    {
        InitializeComponent();

        Text = "STD-AIO | Live Capture";
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.FromArgb(15, 17, 23);
        ClientSize = new Size(500, 250);

        Shown += (_, _) => ConnectRoblox();
        Resize += (_, _) => UpdatePreview();
        FormClosed += (_, _) => StopCapture();
    }

    private static IntPtr FindRobloxWindow()
    {
        var processes = Process.GetProcessesByName("RobloxPlayerBeta");

        var processIds = processes
            .Select(p => (uint)p.Id)
            .ToHashSet();

        IntPtr found = IntPtr.Zero;

        EnumWindowsProc callback = (hwnd, _) =>
        {
            GetWindowThreadProcessId(hwnd, out uint pid);

            if (processIds.Contains(pid) && IsWindowVisible(hwnd))
            {
                found = hwnd;
                return false;
            }

            return true;
        };

        EnumWindows(callback, IntPtr.Zero);

        foreach (var process in processes)
            process.Dispose();

        return found;
    }

    private void ConnectRoblox()
    {
        robloxWindow = FindRobloxWindow();

        if (robloxWindow == IntPtr.Zero)
            return;

        int result = DwmRegisterThumbnail(
            Handle,
            robloxWindow,
            out thumbnail);

        if (result != 0)
        {
            thumbnail = IntPtr.Zero;
            return;
        }

        UpdatePreview();
    }

    private void UpdatePreview()
    {
        if (thumbnail == IntPtr.Zero)
            return;

        if (WindowState == FormWindowState.Minimized)
            return;

        int result = DwmQueryThumbnailSourceSize(
            thumbnail,
            out SIZE source);

        if (result != 0 || source.Width <= 0 || source.Height <= 0)
            return;

        int areaWidth = ClientSize.Width;
        int areaHeight = ClientSize.Height;

        double scale = Math.Min(
            (double)areaWidth / source.Width,
            (double)areaHeight / source.Height);

        int width = (int)(source.Width * scale);
        int height = (int)(source.Height * scale);

        int x = (areaWidth - width) / 2;
        int y = (areaHeight - height) / 2;

        var properties = new ThumbnailProperties
        {
            Flags = RECT_DESTINATION |
                    OPACITY |
                    VISIBLE |
                    SOURCE_CLIENT_AREA,

            Destination = new RECT
            {
                Left = x,
                Top = y,
                Right = x + width,
                Bottom = y + height
            },

            Opacity = 255,
            Visible = true,
            SourceClientAreaOnly = true
        };

        DwmUpdateThumbnailProperties(thumbnail, ref properties);
    }

    private void StopCapture()
    {
        if (thumbnail != IntPtr.Zero)
        {
            DwmUnregisterThumbnail(thumbnail);
            thumbnail = IntPtr.Zero;
        }

        robloxWindow = IntPtr.Zero;
    }
}
